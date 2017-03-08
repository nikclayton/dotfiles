(setq load-prefer-newer t)
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives
             '("marmalade" . "https://marmalade-repo.org/packages/"))
(add-to-list 'package-archives
             '("gnu" . "https://elpa.gnu.org/packages/"))

(package-initialize)

;; Bootstrap auto-compile as early as possible.
(unless (package-installed-p 'auto-compile)
  (package-refresh-contents)
  (package-install 'auto-compile))

(require 'auto-compile)
(auto-compile-on-load-mode)
(auto-compile-on-save-mode)

;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(require 'diminish)
(require 'bind-key)



;; Look and feel

(desktop-save-mode t)			; Save/restore desktop

(tool-bar-mode -1)			; Disable the toolbar
(global-linum-mode 1)			; Line numbers everywhere
(fset 'yes-or-no-p 'y-or-n-p)           ; Always allow y/n for yes/no
(save-place-mode 1)                     ; Save point position in each file
(global-auto-revert-mode)               ; Revert buffers when file changes

(setq ring-bell-function 'ignore)	; No beeping, ever

;; Disable GTK for tooltips, so that the Emacs configured colours and
;; sizes are used.
(set-variable 'x-gtk-use-system-tooltips nil)
(set-variable 'tooltip-frame-parameters
              '((name . "tooltip")
                (internal-border-width . 5)
                (border-width . 1)))

(use-package spaceline
  :ensure t
  :config
  (require 'spaceline-config)
  (spaceline-emacs-theme)
  (spaceline-toggle-buffer-encoding-abbrev-off))

(use-package spaceline-config
  :ensure spaceline
  :config
  (spaceline-spacemacs-theme)
  (spaceline-toggle-buffer-encoding-abbrev-off))

(use-package zenburn-theme
  :ensure t
  :config
  (load-theme 'zenburn t))

(use-package page-break-lines
  :ensure t
  :diminish page-break-lines-mode
  :config
  (global-page-break-lines-mode))

(use-package fill-column-indicator
  :ensure t
  :config
  (setq fci-rule-column 78)
  (setq fci-rule-color
        (cdr (assoc-string "zenburn-yellow-2" zenburn-colors-alist))))

;; fci-mode interacts badly with popup, see
;; https://github.com/alpaker/Fill-Column-Indicator/issues/21
(defun my/fci-enabled-p ()
  (and (boundp 'fci-mode) fci-mode))

(defvar my/fci-mode-suppressed nil)
(defadvice popup-create (before suppress-fci-mode activate)
  "Suspend fci-mode while popups are visible."
  (let ((fci-enabled (my/fci-enabled-p)))
    (when fci-enabled
      (set (make-local-variable 'my/fci-mode-suppressed) fci-enabled)
      (turn-off-fci-mode))))
(defadvice popup-delete (after restore-fci-mode activate)
  "Restore fci-mode when all popups have closed."
  (when (and my/fci-mode-suppressed
	     (null popup-instances))
    (setq my/fci-mode-suppressed nil)
    (turn-on-fci-mode)))

;; "file|directory" rather than "file|<2>"
(use-package uniquify
  :config
  (setq uniquify-buffer-name-style 'post-forward))

;; Smoother window scrolling,
;; https://www.emacswiki.org/emacs/SmoothScrolling.
(setq auto-window-vscroll nil)
(setq mouse-wheel-progressive-speed nil)
(setq mouse-wheel-scroll-amount (quote (2 ((shift) . 1) ((control)))))

(unless (display-graphic-p)
  (xterm-mouse-mode)
  (define-key input-decode-map "\e[1;5C" [(control right)])
  (define-key input-decode-map "\e[1;5D" [(control left)])
  (define-key input-decode-map "\e[1;5E" [(control up)])
  (define-key input-decode-map "\e[1;5F" [(meta left)]))


(setq frame-title-format "%f")


;; Language-agnostic programming tools.

(use-package company
  :ensure t
  :config
  (add-hook 'emacs-lisp-mode-hook #'company-mode))

(use-package company-quickhelp
  :ensure t)

(use-package flycheck
  :ensure t
  :init
  (global-flycheck-mode))

(use-package eldoc
  :ensure t
  :diminish eldoc-mode
  :commands eldoc-mode
  :defer t
  :init
  (add-hook 'emacs-lisp-mode-hook #'eldoc-mode)
  (add-hook 'lisp-interaction-mode-hook #'eldoc-mode))

(use-package ffap
  :defines ido-use-filename-at-point
  :config
  (setq ido-use-filename-at-point 'guess))

;; Emacs-as-IDE.

;; https://github.com/sabof/project-explorer
;; Maybe speedbar instead?
(use-package project-explorer
  :ensure t)

;; Experimenting with sr-speedbar
(use-package sr-speedbar
  :ensure t
  :config
  (speedbar-add-supported-extension ".go")
  (setq sr-speedbar-right-side nil)
  (add-hook
   'go-mode-hook
   #'(lambda ()
       (setq imenu-generic-expression
	     '(("type" "^type *\\([^ \t\n\r\f]*\\)" 1)
	       ("func" "^func *\\(.*\\) {" 1)))
       (imenu-add-to-menubar "Index"))))


;; Markdown stuff

(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :init (setq markdown-command "multimarkdown"))

(use-package flymd
  :ensure t)


;; Typescript editing

(use-package typescript-mode
  :ensure t
  :config
  (setq typescript-indent-level 2))

(use-package tide
  :ensure t)

(defun my/setup-tide-mode ()
  (interactive)
  (tide-setup)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  (company-mode +1))

(add-hook 'before-save-hook #'tide-format-before-save)
(add-hook 'typescript-mode-hook #'my/setup-tide-mode)


;; Packaging things for MELPA

(use-package package-lint
  :ensure t)

(use-package flycheck-package
  :ensure t
  :config
  (eval-after-load 'flycheck
    '(flycheck-package-setup)))



;; Writing LISP
(use-package cl-lib-highlight
  :ensure t
  :defer t
  :config
  (cl-lib-highlight-initialize)
  (cl-lib-highlight-warn-cl-initialize))



;; Go coding

;; (use-package auto-complete
;;   :ensure t
;;   :config
;;   (ac-config-default))

;;(add-to-list 'load-path (concat (getenv "GOPATH")
;;				"src/github.com/nsf/gocode/emacs"))

;; (use-package go-autocomplete
;;   :ensure t
;;   :load-path (lambda ()
;; 	       (concat (getenv "GOPATH") "src/github.com/nsf/gocode/emacs")))

(use-package go-mode
  :ensure t
  :bind (("M-." . godef-jump))
  :config
  (add-hook 'before-save-hook #'gofmt-before-save)
  (add-hook 'go-mode-hook
	    (lambda ()
	      (setq tab-width 2)
	      (setq gofmt-command "goimports")
              (setq company-tooltip-align-annotations t)
	      (go-eldoc-setup)
	      (set (make-local-variable 'company-backends) '(company-go))
	      (company-mode))))

(use-package go-eldoc
  :ensure t
  :config
  (add-hook 'go-mode-hook 'go-eldoc-setup))

(use-package go-guru
  :ensure t)

(use-package go-rename
  :ensure t)

(use-package company-go
  :ensure t)



;; https://www.emacswiki.org/emacs/WinnerMode
(use-package winner
  :ensure t
  :defer t
  :config
  (winner-mode 1))

(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)))

;; C-x u (undo-tree-visualize) to visualize the undo tree.
;; https://www.emacswiki.org/emacs/UndoTree
(use-package undo-tree
  :ensure t
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode)
  (setq undo-tree-visualizer-timestamps t)
  (setq undo-tree-visualizer-diff t))

;; Show key guides on certain prefixes.
;; https://github.com/kai2nenobu/guide-key
(use-package guide-key
  :ensure t
  :defer t
  :diminish guide-key-mode
  :config
  (setq guide-key/guide-key-sequence '("C-x r" "C-x 4" "C-c"))
  (guide-key-mode 1))  ; Enable guide-key-mode

;; Provides a visual mechanism to select the window to switch to.
;; https://github.com/dimitri/switch-window
(use-package switch-window
  :ensure t
  :defer t
  :bind (("C-x o" . switch-window)))

;; Expand the selected region by semantic units.
;; https://github.com/magnars/expand-region.el
(use-package expand-region
  :ensure t
  :defer t
  :bind ("C-=" . er/expand-region))

;; Major mode for editing web-templates.
;; http://web-mode.org/
(use-package web-mode
  :ensure t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (expand-region guide-key undo-tree spaceline el-mock magit org org-dashboard zenburn-theme use-package go-mode company))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "#3F3F3F" :foreground "#DCDCCC" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 80 :width normal :foundry "outline" :family "Source Code Pro")))))


(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/autosave" t)))

(when (file-exists-p "~/.emacs.google.el")
  (load-file "~/.emacs.google.el"))
