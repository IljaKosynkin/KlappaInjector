Pod::Spec.new do |s|
  s.name         = "KlappaInjector"
  s.version      = "1.0.4"
  s.summary      = "Lightweight library for dependency injection using KVC and ObjC-Runtime"

  s.description  = <<-DESC
  I felt like there is no good way to do DI in iOS development at the moment. This library 
  allows you to register objects in Injector and then inject it into arbitrary object.
                   DESC

  s.homepage     = "https://github.com/IljaKosynkin/KlappaInjector"

  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.author             = { "Ilia Kosynkin" => "ilja.kosynkin@gmail.com" }

  s.source       = { :git => "https://github.com/IljaKosynkin/KlappaInjector.git", :tag => "v1.0.4" }

  s.source_files  = "KlappaInjector", "KlappaInjector/*.{h,m}"
  s.exclude_files = "Classes/Exclude"

  s.platform = :ios, '5.0'
end
