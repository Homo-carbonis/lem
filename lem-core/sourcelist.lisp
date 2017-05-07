(in-package :cl-user)
(defpackage :lem.sourcelist
  (:use :cl :lem)
  (:export :with-sourcelist
           :append-sourcelist))
(in-package :lem.sourcelist)

(defvar *sourcelist-point*)
(defvar *current-sourcelist* nil)

(defstruct sourcelist
  buffer-name
  temp-point
  (elements (make-array 0 :adjustable t :fill-pointer 0))
  (index -1))

(defun call-with-sourcelist (buffer-name function)
  (let ((buffer (make-buffer buffer-name))
        (sourcelist (make-sourcelist :buffer-name buffer-name)))
    (erase-buffer buffer)
    (with-point ((*sourcelist-point* (buffer-point buffer) :left-inserting))
      (funcall function sourcelist))
    (buffer-start (buffer-point buffer))
    (change-buffer-mode buffer 'sourcelist-mode t)
    (display-buffer buffer)
    (setf (variable-value 'truncate-lines :buffer buffer) nil)
    (setf *current-sourcelist* sourcelist)))

(defmacro with-sourcelist ((var buffer-name) &body body)
  `(call-with-sourcelist ,buffer-name
                         (lambda (,var)
                           ,@body)))

(defun append-sourcelist (sourcelist write-function jump-function)
  (let ((point *sourcelist-point*))
    (with-point ((start-point point :right-inserting))
      (funcall write-function point)
      (insert-character point #\newline)
      (when jump-function
        (put-text-property start-point
			   point
			   'sourcelist
			   jump-function)
        (vector-push-extend jump-function
                            (sourcelist-elements sourcelist))))))

(defun jump-current-element ()
  (funcall (aref (sourcelist-elements *current-sourcelist*)
                 (sourcelist-index *current-sourcelist*))))

(define-key *global-keymap* "C-x n" 'sourcelist-next)
(define-key *global-keymap* "C-x C-n" 'sourcelist-next)
(define-command sourcelist-next () ()
  (when *current-sourcelist*
    (when (< (1+ (sourcelist-index *current-sourcelist*))
             (length (sourcelist-elements *current-sourcelist*)))
      (incf (sourcelist-index *current-sourcelist*))
      (jump-current-element))))

(define-key *global-keymap* "C-x p" 'sourcelist-previous)
(define-key *global-keymap* "C-x C-p" 'sourcelist-previous)
(define-command sourcelist-previous () ()
  (when *current-sourcelist*
    (when (<= 0 (1- (sourcelist-index *current-sourcelist*)))
      (decf (sourcelist-index *current-sourcelist*))
      (jump-current-element))))

(define-minor-mode sourcelist-mode
    (:name "sourcelist"
	   :keymap *sourcelist-mode-keymap*))

(define-key *sourcelist-mode-keymap* "C-m" 'sourcelist-jump)
(define-key *sourcelist-mode-keymap* "q" 'quit-window)

(define-command sourcelist-jump () ()
  (let ((jump-function (text-property-at (current-point) 'sourcelist)))
    (when jump-function
      (funcall jump-function))))
