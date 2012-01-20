# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'minitest' do
  # with Minitest::Spec
  watch(%r|^spec/(.*)_spec\.rb|)
  watch(%r|^lib/mapsource/(.*)\.rb|) { |m| "spec/integration/#{m[1]}_spec.rb" }
  watch(%r|^lib/mapsource/(.*)\.rb|) { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch(%r|^spec/spec_helper\.rb|)    { "spec" }
end
