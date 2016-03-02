Pod::Spec.new do |s|
  s.name         = "TRAutocompleteView"
  s.version      = "1.2"
  s.summary      = "Flexible and highly configurable auto complete view, attachable to any UITextField"

  s.homepage     = "https://github.com/ashaman/TRAutocompleteView"
  s.license      = 'FreeBSD'
  s.authors       = { "Taras Roshko" => "taras.roshko@gmail.com", "Yaroslav Vorontsov" => "darth.yarius@gmail.com" }

  s.source       = { :git => "https://github.com/ashaman/TRAutocompleteView.git", :tag => "v1.2" }
  s.platform     = :ios, '8.0'
  s.source_files = 'Source'
  s.requires_arc = true
  end
