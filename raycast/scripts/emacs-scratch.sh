#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Emacs Scratch
# @raycast.mode silent
# @raycast.packageName Emacs

if ! emacsclient -n -e t >/dev/null 2>&1; then
  open -a Emacs
  for _ in {1..40}; do
    emacsclient -n -e t >/dev/null 2>&1 && break
    sleep 0.25
  done
fi

emacsclient -n -e '(let ((f (seq-find (lambda (fr) (equal (frame-parameter fr (quote name)) "scratchpad")) (frame-list))))
  (cond
   ((and f (frame-visible-p f) (eq (frame-focus-state f) t))
    (make-frame-invisible f t))
   (f
    (make-frame-visible f)
    (raise-frame f)
    (select-frame-set-input-focus f)
    (switch-to-buffer "*scratch*"))
   (t
    (select-frame-set-input-focus
      (make-frame (quote ((name . "scratchpad") (width . 90) (height . 24) (left . 400) (top . 200) (minibuffer . t)))))
    (switch-to-buffer "*scratch*"))) t)' >/dev/null
