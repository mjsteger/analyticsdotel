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

(defcustom keystroke-markov-state-file "~/.keystrokes-markov"
  "File used to persist the keystrokes across sessions"
  :type 'file
  :group 'analytics)

(defvar *analytics-save-keystrokes-timers '()
  "Timer so that we send the keystrokes every so often")

(defvar last-key nil)
(defvar *functions-count '())
(defvar *keystrokes-count '())
(defvar *keystroke-markov-count '())

(defun save-alist-keystrokes (file)
  (when (not (equal *keystrokes-count nil))
    (with-temp-buffer
      (insert (format "%s" *keystrokes-count))
      (write-region (point-min) (point-max) (eval file)))))

(defun save-alist-functions (file)
  (when (not (equal *functions-count nil))
    (with-temp-buffer
      (insert (format "%s" *functions-count))
      (write-region (point-min) (point-max) (eval file)))))

(defun save-alist-keystrokes-markov (file)
  (when (not (equal *keystroke-markov-count nil))
    (with-temp-buffer
      (insert (format "%s" *keystroke-markov-count))
      (write-region (point-min) (point-max) (eval file)))))

(defun analytics-post-command-hook ()
  (when (not (equal this-command 'self-insert-command))
      (add-function this-command))
  (setq this-command last-command-event)
  (when (not (equal nil last-key))
    (add-keystroke-markov this-command last-key))
  (setq last-key this-command)
  (add-keystroke last-key))

(defun analytics-add-hooks ()
  (add-hook 'post-command-hook 'analytics-post-command-hook)
  (add-hook 'kill-emacs-hook 'send-keystrokes))

(defun load-alist (file variable)
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents-literally file)
      (set variable (read (buffer-string))))))

(defun add-keystroke (key-pressed)
  (let ((key-cell (assoc key-pressed *keystrokes-count)))
     (if (not (equal key-cell nil))
     	(setcdr key-cell (+ 1 (cdr key-cell)))
       (setq *keystrokes-count (cons (cons key-pressed 1) *keystrokes-count)))))

(defun add-function (key-pressed)
  (let ((key-cell (assoc key-pressed *functions-count)))
     (if (not (equal key-cell nil))
     	(setcdr key-cell (+ 1 (cdr key-cell)))
       (setq *functions-count (cons (cons key-pressed 1) *functions-count)))))

(defun add-keystroke-markov (last-key key-pressed)
  (let ((key-cell (assoc last-key (assoc key-pressed *keystroke-markov-count)))
	(key-cell-general (assoc key-pressed *keystroke-markov-count)))
    (if (equal key-cell-general nil)
	(setq *keystroke-markov-count (cons (list key-pressed (list last-key 1)) *keystroke-markov-count))
      (print "yay,the last key is ")(print last-key)
      (print "yay,the key-pressed is ")(print key-pressed )
      (if (equal key-cell nil)
	  (progn
	    (setcdr key-cell-general (cons (list last-key 1) (cdr key-cell-general))))
	(setcdr key-cell (list(+ 1 (cadr key-cell))))
	))))

(defun send-keystrokes ()
  (setq *analytics-save-keystrokes-timers (cons (list (run-with-idle-timer 10 t 'save-alist-functions function-state-file)) *analytics-save-keystrokes-timers))
  (setq *analytics-save-keystrokes-timers (cons (list (run-with-idle-timer 10 t 'save-alist-keystrokes keystroke-state-file)) *analytics-save-keystrokes-timers ))
  (setq *analytics-save-keystrokes-timers (cons (list (run-with-idle-timer 10 t 'save-alist-keystrokes-markov keystroke-markov-state-file)) *analytics-save-keystrokes-timers)))

(defun stop-analytics-timers ()
  (when (not (equal nil *analytics-save-keystrokes-timers))
    (mapcar (lambda (x) (cancel-timer (car x))) *analytics-save-keystrokes-timers)
    (setq *analytics-save-keystrokes-timers nil)))

(defun load-trackers-if-nil ()
  (when (equal nil *functions-count)
    (load-alist function-state-file '*functions-count))
  (when (equal nil *keystrokes-count)
    (load-alist keystroke-state-file '*keystrokes-count))
  (when (equal nil *keystroke-markov-count)
    (load-alist keystroke-markov-state-file '*keystroke-markov-count))
  )

(defun enable-analytics ()
  (analytics-add-hooks)
  (load-trackers-if-nil)
  (stop-analytics-timers)
  (send-keystrokes))
(enable-analytics)

(provide 'analytics)
