;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(add-to-list 'exec-path "/Library/TeX/texbin")

(after! tex-site
  (TeX-modes-set 'TeX-modes TeX-modes))

(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")

(require 'alert)

(defun my/alert-osx-notifier-with-sound (info)
  (start-process "org-notify-osascript" nil "osascript"
                 "-e"
                 (format "display notification %S with title %S sound name \"Ping\""
                         (substring-no-properties (plist-get info :message))
                         (substring-no-properties (plist-get info :title))))
  (alert-message-notify info))

(alert-define-style 'osx-notifier-sound
                     :title "Notify using native OSX notification with sound"
                     :notifier #'my/alert-osx-notifier-with-sound)

(setq alert-default-style 'osx-notifier-sound)

(after! org
  (require 'appt)
  (setq appt-message-warning-time 15
        appt-display-interval 5
        appt-display-mode-line nil
        appt-display-format 'window
        appt-disp-window-function
        (lambda (min-to-app new-time msg)
          (alert msg :title (format "Org Appointment in %s min" min-to-app) :severity 'high)))
  (appt-activate 1)
  (org-agenda-to-appt t)
  (run-with-timer 300 300 (lambda () (org-agenda-to-appt t)))
  (add-hook 'org-finalize-agenda-hook (lambda () (org-agenda-to-appt t)))
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook (lambda () (org-agenda-to-appt t)) nil t))))

(setq doom-theme 'doom-oceanic-next)

(map! :n "C-h" #'evil-window-left
      :n "C-j" #'evil-window-down
      :n "C-k" #'evil-window-up
      :n "C-l" #'evil-window-right)

;; ghostel (libghostty-in-Emacs) puts terminal buffers in evil *insert*
;; state by default, and evil-ghostel forwards C-h/j/k/l straight to the
;; PTY there (C-k/C-l are explicit readline passthroughs, C-j isn't in
;; `ghostel-keymap-exceptions'). That shadows the window-motion bindings
;; above whenever you're actually typing into a TUI (Claude Code, opencode,
;; Codex). Reclaim them in insert state, inside ghostel buffers only.
(after! evil-ghostel
  (evil-define-key* 'insert evil-ghostel-mode-map
    (kbd "C-h") #'evil-window-left
    (kbd "C-j") #'evil-window-down
    (kbd "C-k") #'evil-window-up
    (kbd "C-l") #'evil-window-right))

(map! :after org
      :map org-mode-map
      :n "C-j" #'evil-window-down
      :n "C-k" #'evil-window-up)

(defun siddarth/position-on-line-at-column (line-number column)
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line-number))
    (move-to-column column)
    (point)))

(defun siddarth/restore-visual-block-after-line-move
    (line-number-change mark-line-number mark-column point-line-number point-column)
  (evil-visual-make-selection
   (siddarth/position-on-line-at-column
    (+ mark-line-number line-number-change)
    mark-column)
   (siddarth/position-on-line-at-column
    (+ point-line-number line-number-change)
    point-column)
   'block))

(evil-define-command siddarth/move-selected-lines-down (_selection-start _selection-end)
  :keep-visual t
  (interactive "<r>")
  (let* ((mark-line-number (line-number-at-pos evil-visual-mark))
        (mark-column (save-excursion
                       (goto-char evil-visual-mark)
                       (current-column)))
        (point-line-number (line-number-at-pos evil-visual-point))
        (point-column (save-excursion
                        (goto-char evil-visual-point)
                        (current-column)))
        (first-selected-line
         (siddarth/position-on-line-at-column
          (min mark-line-number point-line-number)
          0))
        (after-last-selected-line
         (siddarth/position-on-line-at-column
          (1+ (max mark-line-number point-line-number))
          0)))
    (when (= after-last-selected-line (point-max))
      (user-error "Selection is already at the bottom"))
    (evil-move first-selected-line
               after-last-selected-line
               (line-number-at-pos after-last-selected-line))
    (siddarth/restore-visual-block-after-line-move
     1 mark-line-number mark-column point-line-number point-column)))

(evil-define-command siddarth/move-selected-lines-up (_selection-start _selection-end)
  :keep-visual t
  (interactive "<r>")
  (let* ((mark-line-number (line-number-at-pos evil-visual-mark))
        (mark-column (save-excursion
                       (goto-char evil-visual-mark)
                       (current-column)))
        (point-line-number (line-number-at-pos evil-visual-point))
        (point-column (save-excursion
                        (goto-char evil-visual-point)
                        (current-column)))
        (first-selected-line
         (siddarth/position-on-line-at-column
          (min mark-line-number point-line-number)
          0))
        (after-last-selected-line
         (siddarth/position-on-line-at-column
          (1+ (max mark-line-number point-line-number))
          0)))
    (when (= first-selected-line (point-min))
      (user-error "Selection is already at the top"))
    (evil-move first-selected-line
               after-last-selected-line
               (- (line-number-at-pos first-selected-line) 2))
    (siddarth/restore-visual-block-after-line-move
     -1 mark-line-number mark-column point-line-number point-column)))

(map! :v "J" #'siddarth/move-selected-lines-down
      :v "K" #'siddarth/move-selected-lines-up)

(map! :after evil-org
      :map evil-org-mode-map
      :v "J" #'siddarth/move-selected-lines-down
      :v "K" #'siddarth/move-selected-lines-up)

(map! :leader
      :prefix ("b" . "buffer")
      :desc "Delete window" "d" #'delete-window
      :desc "Delete other windows" "o" #'delete-other-windows)
(map! "s-P" #'execute-extended-command)

(map! "s-=" #'text-scale-increase
      "s--" #'text-scale-decrease
      "s-+" (cmd! (global-text-scale-adjust 1))
      "s-_" (cmd! (global-text-scale-adjust -1))
      "s-0" (cmd! (text-scale-adjust 0)))

(map! "s-\\" #'split-window-right
      "s-|"  #'split-window-below)

(map! :n "C-d" (cmd! (evil-scroll-down nil)
                     (evil-scroll-line-to-center nil))
      :n "C-u" (cmd! (evil-scroll-up nil)
                     (evil-scroll-line-to-center nil))
      :n "C-a" #'evil-numbers/inc-at-pt
      :n "C-x" #'evil-numbers/dec-at-pt)

;; `~/org/agenda-files' listed bare directories expecting recursive
;; inclusion, but org's directory expansion (`directory-files') is not
;; recursive -- nested files like work/projects/arc.org were silently
;; excluded. Compute the file list directly and recursively instead.
(setq org-agenda-files (directory-files-recursively org-directory "\\.org\\'"))
(map! :map pdf-view-mode-map :n "y" #'pdf-view-kill-ring-save)

;; --- org vault git sync -----------------------------------------------
;; Auto-commit+push on save, and auto-pull once when the vault is first
;; visited, so the two machines stay in sync without manual git commands.

(use-package! git-auto-commit-mode
  :defer t
  :init
  (setq gac-automatically-push-p t
        gac-debounce-interval 10 ; batch rapid successive saves into one commit
        gac-silent-message-p t))

(defun siddarth/org-vault-file-p ()
  (and buffer-file-name
       (file-in-directory-p buffer-file-name (expand-file-name org-directory))))

(add-hook 'org-mode-hook
          (lambda ()
            (when (siddarth/org-vault-file-p)
              (git-auto-commit-mode 1))))

(defvar siddarth/org-vault-pulled-p nil
  "Non-nil once we've pulled the org vault this Emacs session.")

(defun siddarth/org-vault-pull-once ()
  (when (and (siddarth/org-vault-file-p)
             (not siddarth/org-vault-pulled-p))
    (setq siddarth/org-vault-pulled-p t)
    (let ((default-directory (expand-file-name org-directory)))
      (message "Pulling org vault...")
      (make-process
       :name "org-vault-pull"
       :command '("git" "pull" "--rebase" "--autostash")
       :buffer "*org-vault-pull*"
       :sentinel
       (lambda (proc _event)
         (if (zerop (process-exit-status proc))
             (message "Org vault: pulled latest changes.")
           (message "Org vault: pull failed, check *org-vault-pull* buffer.")))))))

(add-hook 'find-file-hook #'siddarth/org-vault-pull-once)

;; --- dotfiles-macos git sync --------------------------------------------
;; Same idea as the org vault above: auto-commit+push on save for any file
;; that lives under dotfiles-macos, including files opened through a
;; symlink (e.g. ~/.config/doom -> ~/dev/dotfiles-macos/doom). Uses
;; find-file-hook rather than a mode hook since dotfiles span many modes.

(defun siddarth/dotfiles-file-p ()
  (and buffer-file-name
       (file-in-directory-p (file-truename buffer-file-name)
                             (expand-file-name "~/dev/dotfiles-macos"))))

(add-hook 'find-file-hook
          (lambda ()
            (when (siddarth/dotfiles-file-p)
              (git-auto-commit-mode 1))))

;; --- Telescope-style floating completion --------------------------------
;; Vertico renders in the minibuffer (bottom of frame) by default; posframe
;; gives it a centered floating window instead, closer to Telescope/fzf.
(use-package! vertico-posframe
  :after vertico
  :config
  (vertico-posframe-mode 1))
