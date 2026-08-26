;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
;;;
;;; Performance
;; Raise threshold during startup
(setq gc-cons-threshold 100000000)
;; Lower it back to a reasonable level after initialization
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold 800000)))


(setenv "LIBRARY_PATH"
        (string-join
         (delq nil
               (list "/opt/homebrew/opt/gcc/lib/gcc/current"
                     "/opt/homebrew/opt/gcc/lib/gcc/current/gcc/aarch64-apple-darwin25/16"
                     (let ((existing (getenv "LIBRARY_PATH")))
                       (and existing (not (string-empty-p existing)) existing))))
         ":"))

;; Without this, native-comp's async trampoline compilation fails with
;; "ld: library 'emutls_w' not found" / "error invoking gcc driver" because
;; libgccjit shells out to gcc for linking and can't find libemutls_w.a,
;; which lives under Homebrew gcc's lib dir rather than a standard path.
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

;; macOS trackpad horizontal (two-finger swipe) scrolling
(setq mouse-wheel-tilt-scroll t
      mouse-wheel-flip-direction t) ; natural scrolling direction

;; Without this, lsp-mode prompts per-file to import a project root and often
;; gets nudged into accepting whatever narrow subfolder the current file
;; lives in (e.g. src/components/ instead of the repo root), which orphans
;; the LSP session from tsconfig.json/Cargo.toml at the real root. Auto-guess
;; walks up to the actual project markers instead of asking.
(after! lsp-mode
  (setq lsp-auto-guess-root t
        ;; clangd supplies semanticTokens; lsp-mode leaves them off by default.
        ;; They distinguish identifiers by their resolved C++ role, rather than
        ;; only by the lexical syntax that font-lock can see.
        lsp-semantic-tokens-enable t))

;; Prefer Homebrew LLVM when installed; otherwise retain the working macOS
;; clangd.  clangd resolves this relative directory from each project root.
(after! lsp-clangd
  (when (file-executable-p "/opt/homebrew/opt/llvm/bin/clangd")
    (setq lsp-clients-clangd-executable
          "/opt/homebrew/opt/llvm/bin/clangd"))
  (cl-pushnew "--compile-commands-dir=build" lsp-clients-clangd-args)
  (set-lsp-priority! 'clangd 2))

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
                         scheduled))
               ;; `org-time-string-to-time' changes match data, so retain the
               ;; captures before parsing the date.
               (let ((date (match-string 1 scheduled))
                     (time (match-string 2 scheduled))
                     (heading (org-get-heading t t t t)))
                 (unless (time-less-p
                          (current-time)
                          (org-time-string-to-time (concat "<" date ">")))
                   (appt-add time heading))))))))))
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

(setq doom-theme 'kanagawa-wave)

;; Emacs Plus's frame-transparency patch provides real macOS backdrop blur.
;; Keep this scoped to that build so regular Emacs never falls back to plain,
;; unblurred transparency.
(when (or (bound-and-true-p ns-emacs-plus-version)
          (string-match-p "/emacs-plus@31/" invocation-directory)
          (string-match-p "/Emacs Glass\\.app/" invocation-directory))
  ;; Keep Emacs Glass independent from the Emacs 30 server.
  (setq server-name "emacs-glass")

  (defun siddarth/apply-macos-glass (&optional frame)
    "Apply frosted-glass styling to FRAME."
    (with-selected-frame (or frame (selected-frame))
      (set-frame-parameter nil 'alpha-background 0.50)
      (set-frame-parameter nil 'ns-background-blur 30)
      (set-frame-parameter nil 'ns-alpha-elements '(ns-alpha-all))))

  ;; Blur must exist while the native NSWindow is being created.
  (add-to-list 'default-frame-alist '(alpha-background . 0.70))
  (add-to-list 'default-frame-alist '(ns-background-blur . 30))
  (add-to-list 'default-frame-alist '(ns-alpha-elements ns-alpha-all))
  (add-hook 'after-make-frame-functions #'siddarth/apply-macos-glass)
  (when (display-graphic-p)
    (siddarth/apply-macos-glass))

  ;; The renamed app bundle defeats With-Editor's "Emacs.app" path heuristic.
  ;; Point it at the matching client through Homebrew's stable opt symlink.
  (setq with-editor-emacsclient-executable
        "/opt/homebrew/opt/emacs-plus@31/bin/emacsclient")
  (after! with-editor
    (setq with-editor-emacsclient-executable
          "/opt/homebrew/opt/emacs-plus@31/bin/emacsclient")))

;; Magit's `executable-find "git"' walks the full PATH on macOS (Homebrew,
;; /usr/bin shim that forwards to Xcode CLT, etc.) on every invocation,
;; adding several seconds to magit-status/commit. Pinning the executable
;; skips the search and drops latency from ~4s to <1s.
(after! magit
  (setq magit-git-executable "/opt/homebrew/bin/git"))

;; Emacs's built-in VC package shells out to git independently of Magit
;; (vc-refresh-state runs on every find-file, save, and revert) and its
;; results go almost entirely unused since Magit has its own status/diff
;; machinery. That's a second, redundant set of git processes forked on top
;; of Magit's own, and is the #1 cause of "everywhere, all the time" Magit
;; sluggishness per Magit's own performance notes. Dropping Git from the
;; backends VC handles stops Emacs from doing that duplicate work.
(setq vc-handled-backends (delq 'Git vc-handled-backends))

(map! :n "C-h" #'evil-window-left
      :n "C-j" #'evil-window-down
      :n "C-k" #'evil-window-up
      :n "C-l" #'evil-window-right
      "C-S-h" #'shrink-window-horizontally
      "C-S-j" #'shrink-window
      "C-S-k" #'enlarge-window
      "C-S-l" #'enlarge-window-horizontally
      ;; Follow wrapped screen lines instead of jumping between file lines.
      :n "j" #'evil-next-visual-line
      :n "k" #'evil-previous-visual-line)

;; Focus the selected split temporarily without making the entire macOS frame
;; fullscreen.  Keep the saved layout on the frame so a second invocation
;; restores precisely the windows that were visible before maximizing.
(defun siddarth/toggle-window-maximize ()
  "Toggle the selected window between focused and its previous layout."
  (interactive)
  (let ((saved-layout (frame-parameter nil 'siddarth--saved-window-layout)))
    (if saved-layout
        (progn
          (set-window-configuration saved-layout)
          (set-frame-parameter nil 'siddarth--saved-window-layout nil))
      (set-frame-parameter nil 'siddarth--saved-window-layout
                           (current-window-configuration))
      (let ((ignore-window-parameters t))
        (delete-other-windows)))))

(map! "S-<escape>" #'siddarth/toggle-window-maximize)

;; Treemacs runs in its own `evil-treemacs-state', not evil normal state, so
;; the global :n bindings above never reach it. Mirror them here.
(after! treemacs-evil
  (define-key! evil-treemacs-state-map
    "C-h" #'evil-window-left
    "C-j" #'evil-window-down
    "C-k" #'evil-window-up
    "C-l" #'evil-window-right
    "C-S-h" #'shrink-window-horizontally
    "C-S-j" #'shrink-window
    "C-S-k" #'enlarge-window
    "C-S-l" #'enlarge-window-horizontally
    "a"   #'treemacs-create-file))

;; Treemacs locks its side-window width by default. The resize commands were
;; correctly bound, but the window refused to honour them.
(after! treemacs
  (setq treemacs-width-is-initially-locked nil)
  (add-hook 'treemacs-mode-hook
            (lambda ()
              (dolist (window (get-buffer-window-list (current-buffer) nil t))
                (set-window-parameter window 'window-size-fixed nil)))))

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
    (kbd "C-S-h") #'shrink-window-horizontally
    (kbd "C-S-j") #'shrink-window
    (kbd "C-S-k") #'enlarge-window
    (kbd "C-S-l") #'enlarge-window-horizontally
    (kbd "S-<escape>") #'siddarth/toggle-window-maximize
    (kbd "C-z") (cmd! (ghostel-send-string "\x1a"))
    (kbd "s-1") #'+workspace/switch-to-0
    (kbd "s-2") #'+workspace/switch-to-1
    (kbd "s-3") #'+workspace/switch-to-2
    (kbd "s-4") #'+workspace/switch-to-3
    (kbd "s-5") #'+workspace/switch-to-4
    (kbd "s-6") #'+workspace/switch-to-5
    (kbd "s-7") #'+workspace/switch-to-6
    (kbd "s-8") #'+workspace/switch-to-7
    (kbd "s-9") #'+workspace/switch-to-final)

  ;; Forward Ctrl-Z to terminal applications such as Codex from either Evil
  ;; state; it is the conventional terminal suspend byte (^Z).
  (evil-define-key* 'emacs evil-ghostel-mode-map
    (kbd "S-<escape>") #'siddarth/toggle-window-maximize
    (kbd "C-z") (cmd! (ghostel-send-string "\x1a")))

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
      :n "C-k" #'evil-window-up
      :n "C-S-h" #'shrink-window-horizontally
      :n "C-S-j" #'shrink-window
      :n "C-S-k" #'enlarge-window
      :n "C-S-l" #'enlarge-window-horizontally)

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
      :v "K" #'siddarth/move-selected-lines-up
      :n "C-S-h" #'shrink-window-horizontally
      :n "C-S-j" #'shrink-window
      :n "C-S-k" #'enlarge-window
      :n "C-S-l" #'enlarge-window-horizontally)

(map! :leader
      :prefix ("b" . "buffer")
      :desc "Delete window" "d" #'delete-window
      :desc "Delete other windows" "o" #'delete-other-windows)
(map! "s-=" #'text-scale-increase
      "s--" #'text-scale-decrease
      "s-+" (cmd! (global-text-scale-adjust 1))
      "s-_" (cmd! (global-text-scale-adjust -1))
      "s-0" (cmd! (text-scale-adjust 0)))

(map! "s-\\" #'split-window-right
      "s-|"  #'split-window-below)

(map! "s-b" #'+treemacs/toggle)

;; A persistent terminal belongs in a side window, not in the current editing
;; window. Cmd-R toggles it; use `codex', `claude', or `opencode' there.
(after! ghostel
  (defconst siddarth/terminal-buffer-name "*terminal*")
  (defvar siddarth/terminal-sidebar-buffer nil)

  (defun siddarth/terminal-sidebar-window ()
    "Return the terminal sidebar window in the selected frame."
    (seq-find (lambda (window)
                (window-parameter window 'siddarth-terminal-sidebar))
              (window-list nil 'no-minibuf)))

  (defun siddarth/create-terminal ()
    "Create and return a fresh Ghostel terminal without changing layout."
    (save-window-excursion
      (let ((ghostel-buffer-name (generate-new-buffer-name "*terminal*")))
        (ghostel))))

  (defun siddarth/show-terminal-sidebar (buffer)
    "Show BUFFER in the persistent right-hand terminal sidebar."
    (setq siddarth/terminal-sidebar-buffer buffer)
    (let ((window (or (siddarth/terminal-sidebar-window)
                      (display-buffer-in-side-window
                       buffer '((side . right) (slot . 0) (window-width . 0.38))))))
      (set-window-parameter window 'siddarth-terminal-sidebar t)
      (set-window-buffer window buffer)
      (select-window window)))

  (defun siddarth/toggle-terminal-sidebar ()
    "Toggle the selected terminal in the persistent sidebar."
    (interactive)
    (if-let ((window (siddarth/terminal-sidebar-window)))
        (delete-window window)
      (siddarth/show-terminal-sidebar
       (or (and (buffer-live-p siddarth/terminal-sidebar-buffer)
                siddarth/terminal-sidebar-buffer)
           (get-buffer siddarth/terminal-buffer-name)
           (siddarth/create-terminal)))))

  (defun siddarth/agent-terminal-p (buffer)
    "Return non-nil when BUFFER is a Ghostel terminal for a coding agent."
    (with-current-buffer buffer
      (and (derived-mode-p 'ghostel-mode)
           (save-excursion
             (save-restriction
               (widen)
               (goto-char (point-min))
               (re-search-forward "codex\\|claude\\|opencode" nil t))))))

  (define-derived-mode siddarth/agent-terminals-mode tabulated-list-mode "Agent Terminals"
    "List live Ghostel terminals running coding agents."
    (setq tabulated-list-format [("Agent terminal" 60 t)])
    (tabulated-list-init-header))

  (defun siddarth/agent-terminals-refresh ()
    "Refresh the agent-terminal list."
    (setq tabulated-list-entries
          (cons '(new-terminal ["[New terminal]"])
                (mapcar (lambda (buffer)
                          (list buffer (vector (buffer-name buffer))))
                        (seq-filter #'siddarth/agent-terminal-p (buffer-list)))))
    (tabulated-list-print t))

  (defun siddarth/agent-terminals-visit ()
    "Put the selected terminal in the Cmd-R sidebar."
    (interactive)
    (when-let ((choice (tabulated-list-get-id)))
      (quit-window)
      (siddarth/show-terminal-sidebar
       (if (eq choice 'new-terminal)
           (siddarth/create-terminal)
         choice))))

  (after! evil
    (evil-define-key 'normal siddarth/agent-terminals-mode-map
      (kbd "RET") #'siddarth/agent-terminals-visit))

  (defun siddarth/toggle-agent-terminals-sidebar ()
    "Toggle a bottom picker for live Codex, Claude Code, and OpenCode terminals."
    (interactive)
    (let ((buffer (get-buffer-create "*Agent Terminals*")))
      (with-current-buffer buffer
        (siddarth/agent-terminals-mode)
        (add-hook 'tabulated-list-revert-hook
                  #'siddarth/agent-terminals-refresh nil t)
        (siddarth/agent-terminals-refresh))
      (if-let ((window (get-buffer-window buffer)))
          (delete-window window)
        (select-window
         (display-buffer-at-bottom buffer '((window-height . 0.25)))))))

  (map! "s-r" #'siddarth/toggle-terminal-sidebar
        "s-R" #'siddarth/toggle-agent-terminals-sidebar))

;; These commands are useful before a terminal buffer exists too, so keep the
;; shortcuts global instead of making them depend on Ghostel having loaded.
(map! "s-r" #'siddarth/toggle-terminal-sidebar
      "s-R" #'siddarth/toggle-agent-terminals-sidebar)

;; Alternative window-resize bindings in normal state: SPC w <, >, -, and +.
(map! :leader
      :prefix ("w" . "window")
      "<" #'shrink-window-horizontally
      ">" #'enlarge-window-horizontally
      "-" #'shrink-window
      "+" #'enlarge-window)

(map! :n "C-d" (cmd! (evil-scroll-down nil)
                     (evil-scroll-line-to-center nil))
      :n "C-u" (cmd! (evil-scroll-up nil)
                     (evil-scroll-line-to-center nil))
      :n "C-a" #'evil-numbers/inc-at-pt
      :n "C-x" #'evil-numbers/dec-at-pt)

;; `~/org/agenda-files' listed bare directories expecting recursive
;; inclusion, but org's directory expansion (`directory-files') is not
;; recursive -- nested files like work/projects/arc.org were silently
;; excluded. Compute the file list directly and recursively instead, then add
;; the GRE task file, which deliberately lives outside the Org vault.
(setq org-agenda-files
      (append (directory-files-recursively org-directory "\\.org\\'")
              '("/Users/siddarth/Documents/gre-prep/gre.org")))
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

(defun siddarth/project-file-search ()
  (interactive)
  (consult-fd
   (or (projectile-project-root)
       default-directory)))

(map! "s-p" #'siddarth/project-file-search
      "s-P" #'execute-extended-command
      "s-F" #'+default/search-project)

(after! consult
  (consult-customize
   consult-fd
   siddarth/project-file-search
   +default/search-project
   :preview-key 'any)

  (defun siddarth/xref-show-definitions (fetcher alist)
    (let ((xrefs (funcall fetcher)))
      (if (= (length xrefs) 1)
          (xref-pop-to-location
           (car xrefs)
           (alist-get 'display-action alist))
        (consult-xref fetcher alist))))

  (setq xref-show-definitions-function
        #'siddarth/xref-show-definitions))

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

;; org mode setup
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
           "NO(N)")))

  (setq org-complete-tags-always-offer-all-agenda-tags t)

  (setq org-agenda-custom-commands
        '(("d" "Daily dashboard"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-start-day nil)))
            (todo "STRT")
            (todo "PROJ")
            (todo "NEXT")
            (todo "WAIT")))

          ("n" "Next tasks" todo "NEXT")
          ("t" "Unprocessed TODOs" todo "TODO")
          ("w" "Waiting tasks" todo "WAIT")
          ("p" "Projects" todo "PROJ")
          ("h" "On hold" todo "HOLD")
          ("i" "Ideas" todo "IDEA")))

  ;; Keep Doom's existing capture templates.
  (add-to-list 'org-capture-templates
               '("P" "Personal task" entry
                 (file "~/org/personal/inbox.org")
                 "* TODO %?\n  %U\n")
               t)

  (add-to-list 'org-capture-templates
               '("W" "Work task" entry
                 (file "~/org/work/inbox.org")
                 "* TODO %?\n  %U\n")
               t)

  (setq org-refile-targets
        '((org-agenda-files :maxlevel . 3)))

  (setq org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil)

  (setq org-habit-graph-column 60
        org-habit-preceding-days 14
        org-habit-following-days 7))
