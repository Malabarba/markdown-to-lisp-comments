;;; markdown-to-lisp-comments.el --- A small set of functions to convert the content of README.md into lisp comment.

;; Copyright (C) 2013 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>
;; URL: http://github.com/BruceConnor/markdown-to-lisp-comments
;; Version: 0.1a
;; Keywords: 
;; Prefix: markdown-to-lisp-comments
;; Separator: -

;;; Commentary:
;;
;; 

;;; Instructions:
;;
;; INSTALLATION
;;
;; This package is available fom Melpa, you may install it by calling
;; M-x package-install.
;;
;; Alternatively, you can download it manually, place it in your
;; `load-path' and require it with
;;
;;     (require 'markdown-to-lisp-comments)

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 

;;; Change Log:
;; 0.1a - 2013/11/05 - first working version.
;;; Code:

(defconst markdown-to-lisp-comments-version "0.1a" "Version of the markdown-to-lisp-comments.el package.")
;; Not really necessary, but useful if you like counting how many versions you've released so far. 
(defconst markdown-to-lisp-comments-version-int 1 "Version of the markdown-to-lisp-comments.el package, as an integer.")
(defun markdown-to-lisp-comments-bug-report ()
  "Opens github issues page in a web browser. Please send any bugs you find.
Please include your emacs and markdown-to-lisp-comments versions."
  (interactive)
  (message "Your markdown-to-lisp-comments-version is: %s, and your emacs version is: %s.
Please include this in your report!"
           markdown-to-lisp-comments-version emacs-version)
  (browse-url "https://github.com/BruceConnor/markdown-to-lisp-comments/issues/new"))

(defun replace-regexp-everywhere (reg rep &optional start end)
  "Version of `replace-regexp' usable in lisp code."
  (goto-char (or start (point-min)))
  (while (re-search-forward reg end t)
    (replace-match rep nil nil)))

(defcustom markdown-to-comments-empty-lines nil
  "If non-nil, empty lines from the markdown file will remain empty (will not be commented)."
  :type 'boolean
  :group 'markdown-to-lisp-comments
  :package-version '(markdown-to-lisp-comments . "0.1a"))

;;;###autoload
(defun markdown-to-comments-convert ()
  "Convert the README.md file into lisp comments, and save to kill-ring.

No files, are altered. The conversion is just saved to kill-ring.
 - If called in a markdown buffer, uses the content of the
   current buffer (or region).
 - If called from a lisp buffer (or anywhere else really), finds
  a markdown file in the current directory (prefering a readme.md
  file) and uses its content for conversion.

The use of this is to keep a package's github documentation (the
readme.md file) in sync with the source file documentation (the
lisp comments at the top)."
  (interactive)
  (let ((text (markdown-to-comments--get-content)))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (search-forward "`" nil :noerror)
        (if (looking-at "M-x\\s-")
            (progn
              (delete-char -1)
              (search-forward-regexp "M-x\\s-+")
              (insert "`")
              (forward-sexp 1)
              (if (looking-at "`")
                  (replace-match "'" :fixedcase :literal)
                (insert "'")
                (search-forward "`")
                (replace-match "" :fixedcase :literal)))
          (let ((m (point)))
            (forward-sexp 1)
            (if (looking-at "`")
                (replace-match "'" :fixedcase :literal)
              (save-excursion
                (insert ">")
                (goto-char m)
                (delete-char -1)
                (insert "<"))))))
      (replace-regexp-everywhere "\\*\"\\([^\"]+\\)\"\\*" "\"\\1\"")
      (replace-regexp-everywhere "^" ";; ")
      (when markdown-to-comments-empty-lines
        (replace-regexp-everywhere "^;;$" ""))
      (goto-char (point-max))
      (when (looking-back "^;; ") (delete-char -3))
      (kill-ring-save (point-min) (point-max))
      (message "Saved result to kill-ring."))))

(defun markdown-to-comments--get-content (&optional file)
  "Description"
  (if file      
      (with-temp-buffer
        (insert-file-contents-literally (expand-file-name file))
        (buffer-substring-no-properties (point-min) (point-max)))  
    (if (eq major-mode 'markdown-mode)
        (let ((l (if (region-active-p) (region-beginning) (point-max)))
              (r (if (region-active-p) (region-end) (point-min))))
          (buffer-substring-no-properties l r))
      (markdown-to-comments--get-content (markdown-to-comments--find-markdown-file)))))

(defun markdown-to-comments--find-markdown-file ()
  "Find the best markdown file in the current directory."
  (let ((case-fold-search t)
        (list (directory-files default-directory nil "\\`.*\\.md\\'" t)))
    (or (car (cl-member "\\`readme\\.md\\'" list :test 'string-match))
        (car list)
        (error "Couldn't find a markdown file in %s!" default-directory))))

;;;###autoload
(defalias 'convert-markdown-to-comments 'markdown-to-comments-convert)

(provide 'markdown-to-lisp-comments)
;;; markdown-to-lisp-comments.el ends here.
