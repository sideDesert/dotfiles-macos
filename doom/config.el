;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(add-to-list 'exec-path "/Library/TeX/texbin")

(after! tex-site
  (TeX-modes-set 'TeX-modes TeX-modes))

(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")

(require 'alert)

(defun my/alert-osx-notifier-with-sound (info)
  (do-applescript
   (format "display notification %S with title %S sound name \"Ping\""
           (plist-get info :message)
           (plist-get info :title)))
  (alert-message-notify info))

(alert-define-style 'osx-notifier-sound
                     :title "Notify using native OSX notification with sound"
                     :notifier #'my/alert-osx-notifier-with-sound)

(setq alert-default-style 'osx-notifier-sound)

(after! org
  (require 'appt)
  (setq appt-display-format 'window
        appt-disp-window-function
        (lambda (min-to-app new-time msg)
          (alert msg :title "Org Appointment" :severity 'high)))
  (appt-activate 1)
  (org-agenda-to-appt))

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

(setq org-agenda-files "~/org/agenda-files")
(map! :map pdf-view-mode-map :n "y" #'pdf-view-kill-ring-save)

;; --- Telescope-style floating completion --------------------------------
;; Vertico renders in the minibuffer (bottom of frame) by default; posframe
;; gives it a centered floating window instead, closer to Telescope/fzf.
(use-package! vertico-posframe
  :after vertico
  :config
  (vertico-posframe-mode 1))
