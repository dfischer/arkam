(defun arkam-mode ()
  "Arkam Mode"
  (interactive)
  (kill-all-local-variables)
  (setq mode-name "arkam-mode")
  (setq major-mode 'arkam-mode)
  (setq indent-tabs-mode nil)
  (setq tab-width 4)
  (run-hooks 'arkam-mode-hook))

(provide 'arkam-mode)
