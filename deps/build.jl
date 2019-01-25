#deps = ["ImagineWorker", "ImagineInterface"]

#for dep in deps
#    if Base.find_in_path(dep) == nothing
#        Pkg.clone("https://github.com/HolyLab/$dep.git")
#        Pkg.build(dep)
#    end
#end
