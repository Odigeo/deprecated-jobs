f = File.join(Rails.root, "config/config.yml")
unless File.exists?(f)
  puts
  puts "-----------------------------------------------------------------------"
  puts "Constant definition file missing. Please copy config/config.yml.example"
  puts "to config/config.yml and tailor its contents to suit your dev setup."
  puts
  puts "NB: config.yml is excluded from git version control as it will contain"
  puts "    data private to your Ocean system."
  puts "-----------------------------------------------------------------------"
  puts
  abort
end
cfg = YAML.load(File.read(f))
cfg.merge! cfg.fetch(Rails.env, {}) if cfg.fetch(Rails.env, {})
cfg.each do |k, v|
  next if k =~ /[a-z]/
  eval "#{k} = #{v.inspect}"
end
