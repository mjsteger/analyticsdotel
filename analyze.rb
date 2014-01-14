require 'rubyvis'

type_to_search = ARGV.first || "functions"
if type_to_search =~ /keystrokes/
  convert_functions = [:to_i, :chr]
else
  convert_functions = [:to_s]
end

root = File.expand_path("~/analytics_emacs")
files = Dir["#{root}/#{type_to_search}*"]


analytics_hash = Hash.new {|hash, key| hash[key] = 0}

files.each do |file|
  File.open(file) do |f|
    f.read.split(/\)/).each do |entry|
      # Split the cons pairs, and make sure there are no left parens
      key, value = entry.gsub(/\(/, "").split(".")
      next if key.nil? || value.nil?
      key = convert_functions.reduce(key, "send")
      analytics_hash[key.strip] += value.to_i
    end
  end
end

nodes = pv.dom(analytics_hash).root("Replace me").nodes

format=Rubyvis::Format.number
color = pv.Colors.category20
vis = pv.Panel.new().width(600).height(1000)
treemap = vis.add(Rubyvis::Layout::Treemap).nodes(nodes).mode("squarify").round(true)

treemap.leaf.add(Rubyvis::Panel).
  fill_style(lambda{|d|
               color.scale(d.parent_node.node_name)}).
  stroke_style("#fff").
  line_width(1).
  antialias(false).
  title(lambda {|d| d.node_name+" "+format.format(d.node_value)})

treemap.node_label.add(Rubyvis::Label).
  text_style(lambda {|d| pv.rgb(0, 0, 0, 1)})

vis.render
File.open("test.svg", "w+"){|f| f.write(vis.to_svg)}
system("open test.svg")
