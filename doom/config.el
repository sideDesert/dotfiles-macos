;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(add-to-list 'exec-path "/Library/TeX/texbin")

(after! tex-site
  (TeX-modes-set 'TeX-modes TeX-modes))

(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")

;; A single long prose/code line (e.g. a long paragraph or match arm) is not
;; the same performance risk as truly minified/generated files. Emacs's
;; default so-long-threshold (250 chars) is low enough that normal org notes
;; and Rust files trip it, silently demoting the buffer out of org-mode/
;; rustic-mode into so-long-mode -- killing font-lock highlighting and (for
;; org agenda files) causing "Agenda file %s is not in Org mode" errors.
(setq so-long-threshold 1000)

;; Without this, lsp-mode prompts per-file to import a project root and often
;; gets nudged into accepting whatever narrow subfolder the current file
;; lives in (e.g. src/components/ instead of the repo root), which orphans
;; the LSP session from tsconfig.json/Cargo.toml at the real root. Auto-guess
;; walks up to the actual project markers instead of asking.
(after! lsp-mode
  (setq lsp-auto-guess-root t))

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
  ;; `org-agenda-to-appt' misses the time on today's occurrence of a
  ;; recurring SCHEDULED timestamp. Keep SCHEDULED as the source of truth,
  ;; but add daily recurring entries to `appt' explicitly.
  (defun my/org-agenda-to-appt-with-repeaters ()
    (interactive)
    (let ((inhibit-message t))
      (org-agenda-to-appt t))
    (dolist (file (org-agenda-files 'unrestricted))
      (with-temp-buffer
        (insert-file-contents file)
        (delay-mode-hooks (org-mode))
        (org-map-entries
         (lambda ()
           (let ((scheduled (org-entry-get nil "SCHEDULED")))
             (when (and scheduled
                        (string-match
                         "^<\\([0-9-]+\\).*?\\([0-9]+:[0-9][0-9]\\).*?\\(?:\\+\\+\\|\\+\\)1d>"
                         scheduled)
                        (not (time-less-p
                              (current-time)
                              (org-time-string-to-time
                               (concat "<" (match-string 1 scheduled) ">")))))
               (appt-add
                (match-string 2 scheduled)
                (org-get-heading t t t t)))))))))
  (setq appt-message-warning-time 15
        appt-display-interval 5
        appt-display-mode-line nil
        appt-display-format 'window
        appt-disp-window-function
        (lambda (min-to-app new-time msg)
          (alert msg :title (format "Org Appointment in %s min" min-to-app) :severity 'high)))
  (appt-activate 1)
  (my/org-agenda-to-appt-with-repeaters)
  (run-with-timer 300 300 #'my/org-agenda-to-appt-with-repeaters)
  (add-hook 'org-finalize-agenda-hook #'my/org-agenda-to-appt-with-repeaters)
  (add-hook 'org-mode-hook
    (lambda ()
      (add-hook 'after-save-hook #'my/org-agenda-to-appt-with-repeaters nil t))))

(setq doom-theme 'doom-oceanic-next)

(map! :n "C-h" #'evil-window-left
      :n "C-j" #'evil-window-down
      :n "C-k" #'evil-window-up
      :n "C-l" #'evil-window-right
      ;; Follow wrapped screen lines instead of jumping between file lines.
      :n "j" #'evil-next-visual-line
      :n "k" #'evil-previous-visual-line)

;; Treemacs runs in its own `evil-treemacs-state', not evil normal state, so
;; the global :n bindings above never reach it. Mirror them here.
(after! treemacs-evil
  (define-key! evil-treemacs-state-map
    "C-h" #'evil-window-left
    "C-j" #'evil-window-down
    "C-k" #'evil-window-up
    "C-l" #'evil-window-right
    "a"   #'treemacs-create-file))

;; ghostel (libghostty-in-Emacs) puts terminal buffers in evil *insert*
;; state by default, and evil-ghostel forwards C-h/j/k/l straight to the
;; PTY there (C-k/C-l are explicit readline passthroughs, C-j isn't in
;; `ghostel-keymap-exceptions'). That shadows the window-motion bindings
;; above whenever you're actually typing into a TUI (Claude Code, opencode,
;; Codex). Reclaim them in insert state, inside ghostel buffers only.
;;
;; Same story for C-z (evil-ghostel deliberately leaves it to evil's
;; `evil-emacs-state' toggle, but nothing pins that down against ghostel's
;; own map) and s-1..s-9 (Doom's `+workspace/switch-to-N' bindings only
;; exist in evil *normal* state, so they're simply absent in insert state).
;;
;; Note: plain C-c is deliberately left alone here (and by evil-ghostel's
;; own passthrough whitelist) since it's Emacs' universal mode-specific-map
;; prefix. Ghostel's base `ghostel-mode-map' already provides terminal
;; control under that prefix regardless of evil state: `C-c C-c' sends
;; SIGINT (use this to interrupt/exit Claude Code), `C-c C-z' suspends,
;; `C-c C-d' sends EOF. Binding plain C-c to a passthrough command here
;; would swallow the prefix and break all of those two-key chords at once.
(after! evil-ghostel
  (evil-define-key* 'insert evil-ghostel-mode-map
    (kbd "C-h") #'evil-window-left
    (kbd "C-j") #'evil-window-down
    (kbd "C-k") #'evil-window-up
    (kbd "C-l") #'evil-window-right
    (kbd "C-z") #'evil-emacs-state
    (kbd "s-1") #'+workspace/switch-to-0
    (kbd "s-2") #'+workspace/switch-to-1
    (kbd "s-3") #'+workspace/switch-to-2
    (kbd "s-4") #'+workspace/switch-to-3
    (kbd "s-5") #'+workspace/switch-to-4
    (kbd "s-6") #'+workspace/switch-to-5
    (kbd "s-7") #'+workspace/switch-to-6
    (kbd "s-8") #'+workspace/switch-to-7
    (kbd "s-9") #'+workspace/switch-to-final)

  ;; ghostel's key-forwarding loop (`ghostel--define-terminal-keys') only
  ;; builds bindings for the "S-" "C-" "M-" "C-S-" "M-S-" "C-M-" modifier
  ;; combos -- it never generates an "s-" (Cmd) variant, so s-<backspace>
  ;; falls through to Emacs/Doom's global map and never reaches the PTY.
  ;; Separately, Shift-Enter and the C-/M-<backspace> word-delete combos do
  ;; reach the PTY, but go through ghostel's generic CSI-u/kitty-protocol
  ;; key encoder, which readline (bash/zsh) and most TUIs -- including
  ;; Claude Code -- don't interpret consistently. Bypass the encoder for
  ;; these specific keys and send the exact bytes those consumers expect:
  ;; \n for a literal newline, ^U (kill-to-start-of-line) for Cmd-Delete,
  ;; ^W (kill-word) for Ctrl-Delete and Option-Delete alike.
  (evil-define-key* 'insert evil-ghostel-mode-map
    (kbd "S-<return>")   (cmd! (ghostel-send-string "\n"))
    (kbd "s-<backspace>") (cmd! (ghostel-send-string "\x15"))
    (kbd "C-<backspace>") (cmd! (ghostel-send-string "\x17"))
    (kbd "M-<backspace>") (cmd! (ghostel-send-string "\x17"))))


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

(map! "s-b" #'+treemacs/toggle)

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

;; --- gd should jump, not prompt -----------------------------------------
;; The :tools lookup module wires xref-show-definitions-function to
;; consult-xref so "SPC c d"/"gd" always shows a completing-read pop-up,
;; even when LSP (clangd/rust-analyzer/typescript-language-server) reports
;; exactly one definition. Auto-jump when there's a single candidate and
;; only fall back to the consult picker when genuinely ambiguous (e.g.
;; multiple trait impls in Rust, or overloaded C++ functions).
(after! consult
  (defun siddarth/xref-show-definitions (fetcher alist)
    (let ((xrefs (funcall fetcher)))
      (if (= (length xrefs) 1)
          (xref-pop-to-location (car xrefs) (alist-get 'display-action alist))
        (consult-xref fetcher alist))))
  (setq xref-show-definitions-function #'siddarth/xref-show-definitions))

;; Neutralize M-m everywhere so Raycast's Opt+M hotkey never fires an Emacs
;; command when the frame happens to be focused. We route it through an
;; emulation-mode keymap so it wins over evil-*-state-map, org-mode-map,
;; and anything else that might bind it.
(defvar siddarth/no-m-m-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "M-m") #'ignore)
    m)

  "Keymap that swallows M-m so Raycast's Opt+M passthrough is a no-op.")

(add-to-list 'emulation-mode-map-alists
             `((t . ,siddarth/no-m-m-map)))

(after! org
  (setq org-todo-keywords
        '((sequence
           "TODO(t)"
           "NEXT(n)"
           "PROJ(p)"
           "LOOP(r)"
           "STRT(s)"
           "WAIT(w)"
           "HOLD(h)"
           "IDEA(i)"
           "|"
           "DONE(d)"
           "KILL(k)")
          (sequence
           "[ ](T)"
           "[-](S)"
           "[?](W)"
           "|"
           "[X](D)")
          (sequence
           "|"
           "OKAY(o)"
           "YES(y)"
           "NO(n)"))))
