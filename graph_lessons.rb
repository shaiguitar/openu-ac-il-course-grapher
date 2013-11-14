# utf-8
require 'graphviz'

require 'pry'
# Create a new graph
g = GraphViz.new( :G, :type => :digraph )

h = {}
# make a script that makes a hash such as:
h['course_wanted'] = [ 'prerequisite1', 'prerequisite2', 'sub_requisite3' ]
h['prerequisite1'] = [ 'sub_requisite1', 'sub_requisite2' ]
h['prerequisite2'] = [ 'sub_requisite2', 'sub_requisite3', 'sub_requisite4' ]

h.each do |course_wanted, prerequisites|
  # init an entry
  node_course_wanted = g.add_nodes(course_wanted)
  prerequisites.each do |prerequisite|
    # init an entry
    node_prerequisite = g.add_nodes(prerequisite)

    # draw the direction
    g.add_edges(node_course_wanted, node_prerequisite)
  end
end

system('rm *png')
# Generate output image
g.output( :png => "course_dep.png" )


