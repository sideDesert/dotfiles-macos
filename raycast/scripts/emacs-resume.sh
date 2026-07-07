#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Emacs Resume
# @raycast.mode silent
# @raycast.packageName Emacs

if ! emacsclient -n -e t >/dev/null 2>&1; then
  open -a Emacs
  for _ in {1..40}; do
    emacsclient -n -e t >/dev/null 2>&1 && break
    sleep 0.25
  done
fi

emacsclient -n -e '(let ((f (seq-find (lambda (fr)
                                        (and (not (equal (frame-parameter fr (quote name)) "scratchpad"))
                                             (display-graphic-p fr)))
                                      (frame-list))))
  (cond
   ((and f (frame-visible-p f) (eq (frame-focus-state f) t))
    (make-frame-invisible f t))
   (f
    (make-frame-visible f)
    (raise-frame f)
    (select-frame-set-input-focus f))
   (t
    (select-frame-set-input-focus (make-frame))))
  t)' >/dev/null

osascript -e 'tell application "Emacs" to activate' >/dev/null 2>&1
