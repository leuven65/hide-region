;;; hide-region.el --- hide regions of text using overlays
;;
;; Copyright (C) 2001, 2005  Mathias Dahl
;;
;; Version: 1.0.1
;; Keywords: hide, region
;; Author: Mathias Dahl <mathias.rem0veth1s.dahl@gmail.com>
;; Maintainer: Mathias Dahl
;; URL: http://mathias.dahl.net/pgm/emacs/elisp/hide-region.el
;;
;; This file is not part of GNU Emacs.
;;
;; This is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
;;
;;; Commentary:
;;
;; The function `hide-region-hide' hides the region. You can hide many
;; different regions and they will be "marked" by two configurable
;; strings (so that you know where the hidden text is).
;;
;; The hidden regions is pushed on a kind of hide-region \"ring".
;;
;; The function `hide-region-unhide' "unhides" one region, starting
;; with the last one you hid.
;;

;;; Code:

(defgroup hide-region nil
  "Functions to hide region using an overlay with the invisible
property. The text is not affected."
  :prefix "hide-region-"
  :group 'convenience)

(defcustom hide-region-set-up-overlay-fn nil
  "function to set the overlay"
  :type 'function
  :group 'hide-region)

(defvar hide-region-folded-face
  '((t (:inherit 'font-lock-keyword-face :box t)))
  "Face for the overlay")

(defvar hide-region-overlays nil
  "Variable to store the regions we put an overlay on.")

(defvar hide-region-overlay-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<tab>") #'hide-region-unhide)
    (define-key map (kbd "n") #'hide-region-next-ov)
    (define-key map (kbd "p") #'hide-region-pre-ov)
    map)
  "Keymap automatically activated inside overlays.
You can re-bind the commands to any keys you prefer.")

(defvar-local hide-region-overlays nil
  "buffer local variable")

;;;###autoload
(defun hide-region-hide (beg end)
  "Hides a region by making an invisible overlay over it and save the
overlay on the hide-region-overlays \"ring\""
  (interactive (when (use-region-p)
                 (list (region-beginning) (region-end))))
  (let ((new-overlay (make-overlay beg end)))
    (add-to-list 'hide-region-overlays new-overlay)
    (if hide-region-set-up-overlay-fn
        (funcall hide-region-set-up-overlay-fn new-overlay)
      (overlay-put new-overlay
                   'display
                   (propertize "..." 'face hide-region-folded-face)))
    (overlay-put new-overlay 'keymap hide-region-overlay-map))
  (deactivate-mark)
  (backward-char) ; to put the point on the overlay
  )

;;;###autoload
(defun hide-region-unhide (ovs)
  "Unhide a region at current pos"
  (interactive (list (overlays-at (point))))
  (seq-map (lambda (ov)
             (let ((start (overlay-start ov))
                   (end (overlay-end ov)))
               (set-mark start)
               (goto-char end)
               (delete-overlay ov)
               ))
           (seq-intersection ovs hide-region-overlays))
  (setq hide-region-overlays
        (set-difference hide-region-overlays ovs))
  )

;;;###autoload
(defun hide-region-toggle-hide ()
  "smart to decide to hide or unhide"
  (interactive)
  (call-interactively (if (region-active-p)
                          #'hide-region-hide
                        #'hide-region-unhide))
  )

;;;###autoload
(defun hide-region-unhide-all ()
  "unhide all the region in the current buffer"
  (interactive)
  (seq-map #'delete-overlay
           hide-region-overlays)
  (setq hide-region-overlays nil))

(defun hide-region-next-ov ()
  "Jump to next ov after current point"
  (interactive)
  (let* ((cur-pos (point))
         (all-ov-pos (seq-map (lambda (_) (overlay-start _))
                              hide-region-overlays))
         (ov-after-pos (seq-filter (lambda (_) (> _ cur-pos)) all-ov-pos)))
    (if ov-after-pos
        (goto-char (seq-min ov-after-pos))
      (user-error "No hide-region after current pos"))
    )
  )

(defun hide-region-pre-ov ()
  "Jump to previous ov before current point"
  (interactive)
  (let* ((cur-pos (point))
         (all-ov-pos (seq-map (lambda (_) (overlay-start _))
                              hide-region-overlays))
         (ov-before-pos (seq-filter (lambda (_) (< _ cur-pos)) all-ov-pos)))
    (if ov-before-pos
        (goto-char (seq-max ov-before-pos))
      (user-error "No hide-region before current pos"))
    )
  )

(provide 'hide-region)

;;; hide-region.el ends here