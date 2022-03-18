# psuedo code:
# dictionary of deps. ( thing -> depends_on )
# get ones that don't have anything they depend on.
# delete those out of anything that depends on it ( the depends_on values )
# batch it up (or run it, etc)
#
# do the same all over again (while loop works well, until we're done with them all).
#
# probably better ways to do it, this is a naive one that was listed on https://breakingcode.wordpress.com/2013/03/11/an-example-dependency-resolution-algorithm-in-python/
#

class DepResolver
  class Node
    def self.from_hash(h)
      h.map { |k,v| Node.new(k, v)}
    end
    def self.name_node_map_from(h)
      nodes = from_hash(h)
      # {a: a, b: b}
      nodes.inject({}) { |ret, n| ret[n.name] = n ; ret }
    end

    attr_reader :name, :deps
    def initialize(name, *deps)
      @name = name
      @deps = deps
    end
  end

  class << self
    def display_graph(nodes)
      nodes.map do |n|
        puts display_node(n)
      end
    end

    def display_node(n)
      if n.deps.empty?
        "#{n.name} -> "
      else
        n.deps.map do |d|
          "#{n.name} -> #{d}"
        end
      end
    end

    def process_graph(name_node_map)
      batch = []
      while !name_node_map.empty?
        ready = name_node_map.select { |name, node| node.deps.empty? }.map(&:first)

        if ready.empty?
          puts "Circular dependency found in remaining graph..."
          nodes = name_node_map.values
          display_graph(nodes)

          circular = nodes.inject([]) { |results, me|

            # if my name is in else's deps, and their name is in my deps.
            depends_on_me = nodes.select{ |n| n.deps.include?(me.name) }
            conflicts = depends_on_me.select{ |n| me.deps.include?(n.name) }

            results << {me.name => conflicts.map(&:name)}
            results
          }
          raise "Cannot resolve: #{circular}"
        end

        ready.each do |name|
          name_node_map.delete(name)
        end

        name_node_map.each { |name, node|
          node.deps.delete_if { |dep| ready.include?(dep) }
        }
        batch << ready
      end

      puts "\nHandle dependencies in this order:\n" + batch.inspect + "\n\n"
      puts batch.join("\n")
    end

  end
end

if __FILE__ == $0

  Node = DepResolver::Node

  a = Node.new(:a)
  b = Node.new(:b)
  c = Node.new(:c, :a)
  d = Node.new(:d, :b)
  e = Node.new(:e, :c, :d)
  f = Node.new(:f, :a, :b)
  g = Node.new(:g, :e, :f)
  h = Node.new(:h, :g)
  i = Node.new(:i, :a)
  j = Node.new(:j, :a)
  k = Node.new(:k, :a)

  NAME_NODE_MAP = {a: a, b: b,c: c, d: d,e: e,f: f, g: g, h: h, i: i, j: j}

  puts "## First map"
  DepResolver.display_graph(NAME_NODE_MAP.values)
  DepResolver.process_graph(NAME_NODE_MAP)

  # reinitialize these, algortithms above mutate the structures.
  a = Node.new(:a, :k)
  b = Node.new(:b)
  c = Node.new(:c, :a)
  d = Node.new(:d, :b)
  e = Node.new(:e, :c, :d)
  f = Node.new(:f, :a, :b)
  g = Node.new(:g, :e, :f)
  h = Node.new(:h, :g)
  i = Node.new(:i, :a)
  j = Node.new(:j, :a)
  k = Node.new(:k, :a) # circular

  BROKEN_NAME_NODE_MAP = {a: a, b: b,c: c, d: d,e: e,f: f, g: g, h: h, i: i, j: j, k: k}

  puts "## Second map"
  begin
    DepResolver.display_graph(BROKEN_NAME_NODE_MAP.values)
    DepResolver.process_graph(BROKEN_NAME_NODE_MAP)
  rescue =>e
    puts e.inspect
  end

  # another broken graph
  a = Node.new(:a)
  b = Node.new(:b, :a, :c)
  c = Node.new(:c, :a, :f)
  d = Node.new(:d, :c, :b)
  e = Node.new(:e, :b, :f)
  f = Node.new(:f, :a)
  g = Node.new(:g, :f, :e, :c, :h, :a)
  h = Node.new(:h, :g)

  BROKEN_NAME_NODE_MAP = {a: a, b: b,c: c, d: d ,e: e,f: f, g: g , h: h}#, i: i, j: j, k: k}

  puts "## Third map"
  begin
    DepResolver.display_graph(BROKEN_NAME_NODE_MAP.values)
    DepResolver.process_graph(BROKEN_NAME_NODE_MAP)
  rescue =>e
    puts e.inspect
  end

end
