(defpackage :lem-vi-mode/tests/options
  (:use :cl
        :lem
        :rove
        :lem-vi-mode/options
        :lem-vi-mode/tests/utils)
  (:import-from :lem-fake-interface
                :with-fake-interface)
  (:shadowing-import-from :lem-vi-mode/tests/utils
                          :with-current-buffer)
  (:import-from :named-readtables
                :in-readtable))
(in-package :lem-vi-mode/tests/options)

(in-readtable :interpol-syntax)

(deftest get-option
  (ok (typep (get-option "number") 'option)
      "Can get a global option")
  (ok (typep (get-option "iskeyword") 'option)
      "Can get a buffer-local option")
  (let ((isk (option-value "iskeyword")))
    (setf (option-value "iskeyword") '("@" "_"))
    (ok (equalp (option-value "iskeyword") '("@" "_"))
        "Can set a buffer-local option")
    (with-fake-interface ()
      (with-test-buffer (buf "abc")
        (with-current-buffer (buf)
          (ok (equalp (option-value "iskeyword") isk)
              "Another buffer's local option is not changed"))))))

(deftest non-broad-word-char-option
  (ok (typep (get-option "non-broad-word-char") 'option)
      "Can get non-broad-word-char option")
  (ok (typep (get-option "nbwc") 'option)
      "Can get non-broad-word-char option by alias")
  (with-fake-interface ()
    (with-vi-buffer (#?"abc\n[(]def)\n")
      (cmd "E")
      (ok (buf= #?"abc\n(def[)]\n")))
    (with-vi-buffer (#?"abc\n[(]def)\n")
      (execute-set-command "nbwc+=(")
      (execute-set-command "nbwc+=)")
      (cmd "WE")
      (ok (buf= #?"abc\n(de[f])\n")))))