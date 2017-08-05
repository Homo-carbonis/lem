(in-package :lem)

(export '(*before-init-hook*
          *after-init-hook*
          lem))

(defvar *before-init-hook* '())
(defvar *after-init-hook* '())

(defvar *in-the-editor* nil)

(defvar *syntax-scan-window-recursive-p* nil)

(defun syntax-scan-window (window)
  (check-type window window)
  (when (and (enable-syntax-highlight-p (window-buffer window))
             (null *syntax-scan-window-recursive-p*))
    (let ((*syntax-scan-window-recursive-p* t))
      (syntax-scan-region
       (line-start (copy-point (window-view-point window) :temporary))
       (or (line-offset (copy-point (window-view-point window) :temporary)
                        (window-height window))
           (buffer-end-point (window-buffer window)))))))

(defun syntax-scan-buffer (buffer)
  (check-type buffer buffer)
  (syntax-scan-region
   (buffer-start-point buffer)
   (buffer-end-point buffer)))

(let ((once nil))
  (defun setup ()
    (unless once
      (setf once t)
      (window-init)
      (minibuf-init)
      (start-idle-timer 100 t
                        (lambda ()
                          (syntax-scan-window (current-window))))
      (add-hook *window-scroll-functions*
                (lambda (window)
                  (syntax-scan-window window)))
      (add-hook *window-size-change-functions*
                (lambda (window)
                  (syntax-scan-window window)))
      (add-hook *window-show-buffer-functions*
                (lambda (window)
                  (syntax-scan-window window)))
      (add-hook (variable-value 'after-change-functions :global)
                (lambda (start end old-len)
                  (declare (ignore old-len))
                  (syntax-scan-region start end)))
      (add-hook *find-file-hook*
                (lambda (buffer)
                  (prepare-auto-mode buffer)
                  (scan-file-property-list buffer)
                  (syntax-scan-buffer buffer))
                5000)
      (add-hook *before-save-hook*
                (lambda (buffer)
                  (scan-file-property-list buffer))))))

(defun lem-internal (initialize-function)
  (let* ((main-thread (bt:current-thread))
         (editor-thread (bt:make-thread
                         (lambda ()
                           (let ((report (toplevel-command-loop
                                          initialize-function)))
                             (bt:interrupt-thread
                              main-thread
                              (lambda ()
                                (error 'exit-editor :value report)))))
                         :name "editor")))
    (handler-case (input-loop editor-thread)
      (exit-editor (c) (return-from lem-internal (exit-editor-value c))))))

(defstruct command-line-arguments
  args
  (no-init-file nil))

(defun parse-args (args)
  (let ((parsed-args
          (make-command-line-arguments)))
    (setf (command-line-arguments-args parsed-args)
          (loop :while args
                :for arg := (pop args)
                :when (cond ((member arg '("-q" "--no-init-file") :test #'equal)
                             (setf (command-line-arguments-no-init-file parsed-args)
                                   t)
                             nil)
                            ((or (stringp arg) (pathnamep arg))
                             `(find-file ,(merge-pathnames arg (uiop:getcwd))))
                            (t
                             arg))
                :collect it))
    parsed-args))

(defun apply-args (args)
  (mapc #'eval (command-line-arguments-args args)))

(let ((once nil))
  (defun init (args)
    (unless once
      (setf once t)
      (run-hooks *before-init-hook*)
      (unless (command-line-arguments-no-init-file args)
        (load-init-file))
      (run-hooks *after-init-hook*))
    (apply-args args)))

(defun run-lem (args)
  (let ((report
          (with-catch-bailout
            (handler-bind ((error #'bailout)
                           #+sbcl (sb-sys:interactive-interrupt #'bailout))
              (call-with-screen
               (lambda ()
                 (unwind-protect
                      (progn
                        (setf *in-the-editor* t)
                        (setup)
                        (lem-internal
                         (lambda ()
                           (init args))))
                   (setf *in-the-editor* nil))))))))
    (when report
      (format t "~&~A~%" report))))

(defun lem (&rest args)
  (setf args (parse-args args))
  (if *in-the-editor*
      (apply-args args)
      (run-lem args)))
