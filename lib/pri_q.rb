require 'pri_q/version'
require 'thread'

class PriQ

  def initialize
    @que = {}
    @que.taint
    @num_waiting = 0
    self.taint
    @mutex = Mutex.new
    @cond = ConditionVariable.new
    @min = nil
    @length = 0
    @root_list = nil
  end

  def clear
    Thread.handle_interrupt(StandardError => :on_blocking) do
      @mutex.synchronize do
        @que.clear
      end
    end
  end

  def empty?
    @root_list.empty?
  end

  def length
    @que.length.dup.freeze
  end

  def num_waiting
    @num_waiting.dup.freeze
  end

  def pop(non_block=false)
    Thread.handle_interrupt(StandardError => :on_blocking) do
      @mutex.synchronize do
        while true
          if @que.empty?
            if non_block
              raise ThreadError, 'queue empty'
            else
              begin
                @num_waiting += 1
                @cond.wait @mutex
              ensure
                @num_waiting -= 1
              end
            end
          else
            return self.delete_min_return_key
          end
        end
      end
    end
  end

  # Add an object to the queue
  def push(obj, priority)
    Thread.handle_interrupt(StandardError => :on_blocking) do
      @mutex.synchronize do
        return self.change_priority(obj, priority) if @que[obj]
        node = Node.new(obj, priority)
        @que[obj] = node
        @min = node if !@min or priority < @min.priority
        if @root_list.nil?
          @root_list = node
          node.right = node
          node.left = node.right
        else
          node.left = @root_list.left
          node.right = @root_list
          @root_list.left.right = node
          @root_list.left = node
        end
        @length += 1
        self
        @cond.signal
      end
    end
  end

  def change_priority(key, priority)
    return self.push(key, priority) unless @que[key]

    node = @que[key]
    if node.priority < priority # Priority increased removing node and reinserting
      self.delete(key)
      self.push(key, priority)
      return self
    end
    node.priority = priority
    @min = node if node.priority < @min.priority

    return self unless node.parent or node.parent.priority <= node.priority # Already in rootlist or bigger than parent
    begin
      parent = node.parent
      self.cut_node(node)
      node = parent
    end while node.mark and node.parent
    node.mark = true if node.parent

    self
  end

  # call-seq:
  #     [key] -> priority
  #
  # Return the priority of a key or nil if the key is not in the queue.
  #
  #     q = PriorityQueue.new
  #     (0..10).each do | i | q[i.to_s] = i end
  #     q["5"] #=> 5
  #     q[5] #=> nil
  def [](obj)
    @que[obj] and @que[obj].priority
  end

  # call-seq:
  #     has_key? key -> boolean
  #
  # Return false if the key is not in the queue, true otherwise.
  #
  #     q = PriorityQueue.new
  #     (0..10).each do | i | q[i.to_s] = i end
  #     q.has_key("5") #=> true
  #     q.has_key(5)   #=> false
  def has_key?(key)
    @que.has_key?(key)
  end

  def each

  end

  private

  def cut_node(node)
    return self unless node.parent
    node.parent.degree -= 1
    if node.parent.child == node
      if node.right == node
        node.parent.child = nil
      else
        node.parent.child = node.right
      end
    end
    node.parent = nil
    node.right.left = node.left
    node.left.right = node.right

    node.right = @root_list
    node.left = @root_list.left
    @root_list.left.right = node
    @root_list.left = node

    node.mark = false

    self
  end

  # Internal class Node
  class Node # :nodoc:
    attr_accessor :parent, :child, :left, :right, :key, :priority, :degree, :mark

    def initialize(key, priority)
      @key, @priority, @degree = key, priority, 0
    end

    def child=(child)
      raise 'Circular Child' if child == self
      raise 'Child is neighbour' if child == self.right
      raise 'Child is neighbour' if child == self.left
      @child = child
    end
  end


end
