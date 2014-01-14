(require 'calendar)
(defgroup analytics nil
"The Analytics platform that Mikey is writing")
; Use the standard American way of displaying dates
(setq calendar-date-display-form '(month "-" day "-" year))

(defvar *temp-alist nil)

(defcustom function-state-file "~/analytics_emacs/functions"
  "file used to persist the functions and placement across sessions"
  :type 'file
  :group 'analytics)

(defcustom keystroke-state-file "~/analytics_emacs/keystrokes"
  "File used to persist the keystrokes across sessions"
  :type 'file
  :group 'analytics)

(defvar *analytics-save-keystrokes-timer nil
"Timer so that we send the keystrokes every so often")

(defvar *functions-count #s(hash-table size 1000 test equal data ()))
(defvar *keystrokes-count #s(hash-table size 2000 test equal data()))
(defvar *keystrokes-markov-count #s(hash-table size 2000 test equal data()))

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

(defun add-keystroke-markov (hash this-letter previous-letter)
  (puthash hash (+ 1 (gethash this-letter hash))))

(defun analytics-post-command-hook ()
  (if (not (equal this-command 'self-insert-command))
      (add-keystroke *functions-count this-command)
    (setq last-key last-command-event)
    (add-keystroke *keystrokes-count last-command-event)))

(defun analytics-add-hooks ()
  (add-hook 'post-command-hook 'analytics-post-command-hook)
  (add-hook 'kill-emacs-hook 'send-keystrokes-directly))

(defun send-keystrokes-directly ()
  (save-alist (filename-with-date function-state-file "functions") *functions-count)
  (save-alist (filename-with-date keystroke-state-file "keystrokes") *keystrokes-count))

(defun send-keystrokes ()
  (run-with-idle-timer 60 t 'save-alist (filename-with-date function-state-file "functions") *functions-count)
  (run-with-idle-timer 60 t 'save-alist (filename-with-date keystroke-state-file "keystrokes") *keystrokes-count))

(defun analytics-remove-hooks()
  (remove-hook 'post-command-hook 'analytics-post-command-hook))

(defun filename-with-date (filename data)
  (concat filename "-" (calendar-date-string (calendar-current-date)) ))

(provide 'analytics)

(analytics-add-hooks)
(send-keystrokes)

