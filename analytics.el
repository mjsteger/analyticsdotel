(defgroup analytics nil
"The Analytics platform that Mikey is writing")

(defvar *temp-alist nil)

(defcustom function-state-file "~/.functions"
  "file used to persist the functions and placement across sessions"
  :type 'file
  :group 'analytics)

(defcustom keystroke-state-file "~/.keystrokes"
  "File used to persist the keystrokes across sessions"
  :type 'file
  :group 'analytics)

(defvar *analytics-save-keystrokes-timer nil
"Timer so that we send the keystrokes every so often")

(defvar *functions-count #s(hash-table size 1000 test equal data ()))
(defvar *keystrokes-count #s(hash-table size 2000 test equal data()))


(defun hash-to-alist (key value)
  (setq *temp-alist (cons (cons key value) *temp-alist)))

(defun hashToAlist (hash)
  (setq *temp-alist nil)
  (maphash 'hash-to-alist hash))

(defun getKeystrokeForCommand (command valueToSet)
  (with-temp-buffer
    (where-is command t)
    (set valueToSet (eval (buffer-string)))))


(defun load-hash (file variable)
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents-literally file)
      (set variable (eval (buffer-string))))))

(defun save-alist (file variable)
  (when (not(equal variable nil))
    (hashToAlist variable)
    (with-temp-buffer
      (insert (format "%s" *temp-alist))
      (write-region (point-min) (point-max) (eval file)))))


(defun add-keystroke (variable command)
  (puthash command (+ 1 (gethash command variable 0)) variable))

;;(add-hook 'post-self-insert-hook 'analytics-post-insert-hook)

(defun analytics-post-command-hook ()
  (if (not(equal this-command 'self-insert-command))
      (add-keystroke *functions-count this-command)
    (add-keystroke *keystrokes-count last-command-event)))

(defun analytics-add-hooks ()
  (add-hook 'post-command-hook 'analytics-post-command-hook))
;; (defun analytics-post-insert-hook ()
;;   (add-keystroke *keystrokes-count last-command-event))

(save-alist keystroke-state-file *keystrokes-count)
(defun send-keystrokes ()
  (run-with-timer 1 nil 'save-alist function-state-file *functions-count)
  (run-with-timer 1 nil 'save-alist keystroke-state-file *keystrokes-count))

(provide 'analytics)
(analytics-add-hooks)
(send-keystrokes)

