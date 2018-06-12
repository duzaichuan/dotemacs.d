(use-package eshell
  :ensure t
  :bind (([f1] . eshell)
	 :map comint-mode-map
	 ([up] . comint-previous-input)
	 ([down] . comint-next-input))
  :hook (eshell-mode . visual-line-mode)
  :commands eshell-mode
  :init
  (add-hook 'eshell-mode-hook
            (lambda ()
              (eshell/export "NODE_NO_READLINE=1")))
  :config
  (progn
    (use-package magit)
    (defmacro with-face (STR &rest PROPS)
      "Return STR propertized with PROPS."
      `(propertize ,STR 'face (list ,@PROPS)))

    (defmacro esh-section (NAME ICON FORM &rest PROPS)
      "Build eshell section NAME with ICON prepended to evaled FORM with PROPS."
      `(setq ,NAME
             (lambda () (when ,FORM
			  (-> ,ICON
			      (concat esh-section-delim ,FORM)
			      (with-face ,@PROPS))))
	     ))

    (defun esh-acc (acc x)
      "Accumulator for evaluating and concatenating esh-sections."
      (--if-let (funcall x)
	  (if (s-blank? acc)
              it
            (concat acc esh-sep it))
	acc))

    (defun esh-prompt-func ()
      "Build `eshell-prompt-function'"
      (concat esh-header
              (-reduce-from 'esh-acc "" eshell-funcs)
              "\n"
              eshell-prompt-string))

    (esh-section esh-dir
		 "\xf07c"  ;  (faicon folder)
		 (abbreviate-file-name (eshell/pwd))
		 '(:bold ultra-bold :underline t))

    (esh-section esh-git
		 "\xe907"  ;  (git icon)
		 (magit-get-current-branch))

    ;; Below I implement a "prompt number" section
    (setq esh-prompt-num 0)
    (add-hook 'eshell-exit-hook (lambda () (setq esh-prompt-num 0)))
    (advice-add 'eshell-send-input :before
		(lambda (&rest args) (setq esh-prompt-num (incf esh-prompt-num))))

    (esh-section esh-num
		 "\xf0c9"  ;  (list icon)
		 (number-to-string esh-prompt-num))

    ;; Separator between esh-sections
    (setq esh-sep "  ")  ; or " | "

    ;; Separator between an esh-section icon and form
    (setq esh-section-delim " ")

    ;; Eshell prompt header
    (setq esh-header " ")  ; or "\n┌─"

    ;; Eshell prompt regexp and string. Unless you are varying the prompt by eg.
    ;; your login, these can be the same.
    (setq eshell-prompt-regexp "$ ")   ; or "└─> "
    (setq eshell-prompt-string "$ ")   ; or "└─> "

    ;; Choose which eshell-funcs to enable
    (setq eshell-funcs (list esh-dir esh-git esh-num))

    ;; Enable the new eshell prompt
    (setq eshell-prompt-function 'esh-prompt-func)

  ))

(use-package eshell-fringe-status
  :ensure t
  :hook (eshell-mode . eshell-fringe-status-mode))

(use-package esh-autosuggest
  :ensure t
  :hook (eshell-mode . esh-autosuggest-mode))

(provide 'du-shell)
