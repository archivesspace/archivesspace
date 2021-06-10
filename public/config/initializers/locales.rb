I18n.prioritize_plugins!
I18n.load_path = I18n.load_path.reject { |p| !p.match /frontend\// } + I18n.load_path.reject { |p| p.match /frontend\// }
