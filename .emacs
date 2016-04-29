(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(inhibit-startup-screen t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(add-to-list 'load-path "~/.emacs.d/lisp/")

;; xmpfilter, see http://www.rubytapas.com/episodes/56-xmpfilter
;; need to "gem install rcodetools"
(require 'rcodetools)
(require 'ruby-mode)
(define-key ruby-mode-map (kbd "C-c M-c") 'xmp)

;; MELPA Repository
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)

(setq-default indent-tabs-mode nil)

;; Java - fix indent issue with anonymous classes
(c-set-offset 'inexpr-class 0)

;; Java - "shallow" indent instead of "deep" indent
(defun my-indent-setup ()
  (c-set-offset 'arglist-intro '+))
(add-hook 'java-mode-hook 'my-indent-setup)

;; Java - treat annotations like comments to prevent method indentation
(add-hook 'java-mode-hook
	  '(lambda ()
         "Treat Java 1.5 @-style annotations as comments."
         (setq c-comment-start-regexp
           "\\(@\\|/\\(/\\|[*][*]?\\)\\)")
         (modify-syntax-entry ?@ "< b"
			      java-mode-syntax-table)))

;; Java - fix indentation
(add-hook 'java-mode-hook (lambda ()
			    (setq
			     indent-tabs-mode nil
			     c-basic-offset 4
			     )))

;; Ruby - "shallow" indent instead of "deep" indent
(setq ruby-deep-indent-paren nil)

;; Ruby - don't insert magic encoding comment on save
(setq ruby-insert-encoding-magic-comment nil)

;; CSS - 2 space indent
(setq css-indent-offset 4)

;; SCSS - disable compile at save
(setq scss-compile-at-save nil)

;; Coffee - 2 space indent
(custom-set-variables '(coffee-tab-width 2))


;;;; Hooks ;;;;

;; delete trailing whitespace before save
(add-hook 'before-save-hook 'delete-trailing-whitespace)


;;;; File Extensions ;;;;

;; Ruby/Rails
(add-to-list 'auto-mode-alist '("\\.rake\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.jbuilder\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\Capfile\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\Rakefile\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\Gemfile\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\Gemfile.local\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.gemspec\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.tailor\\'" . ruby-mode))

;; ColdFusion
(add-to-list 'auto-mode-alist '("\\.cfm\\'" . xml-mode))
(add-to-list 'auto-mode-alist '("\\.cfc\\'" . xml-mode))

;; JS
(add-to-list 'auto-mode-alist '("\\.js.erb\\'" . js-mode))

(add-hook 'html-mode-hook
	  (lambda ()
	    ;; Default indentation is usually 2 spaces, changing to 4.
	    (set (make-local-variable 'sgml-basic-offset) 4)))

;; XML - add new lines
(defun bf-pretty-print-xml-region (begin end)
  "Pretty format XML markup in region. You need to have nxml-mode
http://www.emacswiki.org/cgi-bin/wiki/NxmlMode installed to do
this.  The function inserts linebreaks to separate tags that have
nothing but whitespace between them.  It then indents the markup
by using nxml's indentation rules."
  (interactive "r")
  (save-excursion
      (nxml-mode)
      (goto-char begin)
      (while (search-forward-regexp "\>[ \\t]*\<" nil t)
        (backward-char) (insert "\n"))
      (indent-region begin end))
    (message "Ah, much better!"))


;; JSON
(require 'json)

(defun json-reformat:indent (level)
  (make-string (* level 4) ? ))

(defun json-reformat:p-of-number (val)
  (number-to-string val))

(defun json-reformat:p-of-list (val level)
  (concat "{\n" (json:list-to-string val (1+ level)) (json-reformat:indent level) "}"))

(defun json-reformat:p-of-vector (val level)
  (if (= (length val) 0) "[]"
    (concat "[\n"
            (mapconcat
             'identity
             (loop for v across val
                   collect (concat
                            (json-reformat:indent (1+ level))
                            (json-reformat:print-value v (1+ level))
                            ))
             (concat ",\n"))
            "\n" (json-reformat:indent level) "]"
            )))

(defun json-reformat:p-of-symbol (val)
  (cond ((equal 't val) "true")
        ((equal json-false val) "false")
        (t (symbol-name val))))

(defun json-reformat:print-value (val level)
  (cond ((consp val) (json-reformat:p-of-list val level))
        ((numberp val) (json-reformat:p-of-number val))
        ((vectorp val) (json-reformat:p-of-vector val level))
        ((null val) "null")
        ((symbolp val) (json-reformat:p-of-symbol val))
        (t (json-encode-string val))))

(defun json:list-to-string (root level)
  (let (key val str)
    (while root
      (setq key (car root)
            val (cadr root)
            root (cddr root))
      (setq str
            (concat str (json-reformat:indent level)
                    "\"" key "\""
                    ": "
                    (json-reformat:print-value val level)
                    (when root ",")
                    "\n"
                    )))
    str))

(defun json-reformat-region (begin end)
  (message "gist.github.com/gongo/1789605 is moved to github.com/gongo/json-reformat.
This repository is not maintained.")
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      (let* ((json-key-type 'string)
             (json-object-type 'plist)
             (before (buffer-substring (point-min) (point-max)))
             (json-tree (json-read-from-string before))
             after)
        (setq after (json-reformat:p-of-list json-tree 0))
        (delete-region (point-min) (point-max))
        (insert after)))))

(provide 'json-reformat)


;; Malabar Mode (Java)
;; (require 'cedet)
;; (require 'semantic)
;; (load "semantic/loaddefs.el")
;; (semantic-mode 1);;
;; (require 'malabar-mode)
;; (add-to-list 'auto-mode-alist '("\\.java\\'" . malabar-mode))

(defun pbcopy ()
  (interactive)
  (call-process-region (point) (mark) "pbcopy")
  (setq deactivate-mark t))

(defun pbpaste ()
  (interactive)
  (call-process-region (point) (if mark-active (mark) (point)) "pbpaste" t t))

(defun pbcut ()
  (interactive)
  (pbcopy)
  (delete-region (region-beginning) (region-end)))

(global-set-key (kbd "C-c c") 'pbcopy)
(global-set-key (kbd "C-c v") 'pbpaste)
(global-set-key (kbd "C-c x") 'pbcut)

(defun rename-file-and-buffer ()
  "Rename the current buffer and file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (message "Buffer is not visiting a file!")
      (let ((new-name (read-file-name "New name: " filename)))
        (cond
         ((vc-backend filename) (vc-rename-file filename new-name))
         (t
          (rename-file filename new-name t)
          (set-visited-file-name new-name t t)))))))
