(defpackage :lem
  (:use :cl)
  (:export :lem)
  (:shadow :y-or-n-p :read-char :apropos))

(defsystem lem
  :serial t
  :components ((:file "wrappers")
	       (:file "key")
	       (:file "globals")
	       (:file "util")
               (:file "macros")
               (:file "hooks")
	       (:file "keymap")
	       (:file "command")
               (:file "comp")
	       (:file "minibuf")
	       (:file "kill")
	       (:file "point")
	       (:file "search")
	       (:file "region")
	       (:file "buffer")
	       (:file "buffers")
	       (:file "bufed")
	       (:file "process")
	       (:file "window")
	       (:file "file")
	       (:file "word")
	       (:file "mode")
               (:file "sexp")
	       (:file "lisp-mode")
               (:file "grep")
	       (:file "lem"))
  :depends-on (:cl-ncurses
               #+sbcl :sb-posix
               :bordeaux-threads))
