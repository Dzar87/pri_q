require 'thread'

class PriQ

  def initialize
    @que = [nil]
    @que.taint
    @num_waiting = 0
    self.taint
    @mutex = Mutex.new
    @cond = ConditionVariable.new
  end

  def clear
    @que.clear
  end

  def empty?
    @que.empty?
  end

  def length
    @que.length
  end

  def num_waiting
    @num_waiting
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
            # exchange the root with the last element
            exchange(1, @que.size - 1)

            # remove the last element of the list
            max = @que.pop.obj rescue max = nil

            # and make sure the tree ordered again
            bubble_down(1)
            return max
          end
        end
      end
    end
  end

  def push(obj, priority=1)
    Thread.handle_interrupt(StandardError => :on_blocking) do
      @mutex.synchronize do
        @que.push Element.new(obj, priority)
        bubble_up(@que.size - 1)
        @cond.signal
      end
    end
  end

  private

  def bubble_up(index)
    parent_index = (index / 2)

    # return if we reach the root element
    return if index <= 1

    # or if the parent is already greater than the child
    return if @que[parent_index] >= @que[index]

    # otherwise we exchange the child with the parent
    exchange(index, parent_index)

    # and keep bubbling up
    bubble_up(parent_index)
  end

  def exchange(source, target)
    @que[source], @que[target] = @que[target], @que[source]
  end

  def bubble_down(index)
    child_index = (index * 2)

    # stop if we reach the bottom of the tree
    return if child_index > @que.size - 1

    # make sure we get the largest child
    not_the_last_element = child_index < @que.size - 1
    left_element = @que[child_index]
    right_element = @que[child_index + 1]
    child_index += 1 if not_the_last_element && right_element > left_element

    # there is no need to continue if the parent element if already bigger
    # then its children
    return if @que[index] >= @que[child_index]

    exchange(index, child_index)

    # repeat the process until we reach a point where the parent
    # is larger than its children
    bubble_down(child_index)
  end

  class Element
    include Comparable

    attr_accessor :obj, :priority

    def initialize(obj, priority)
      @obj, @priority = obj, priority
    end

    def <=>(other)
      other.priority <=> @priority
    end
  end

  alias_method :shift, :pop
  alias_method :deq, :pop
  alias_method :<<, :push
  alias_method :enq, :push
  alias_method :size, :length
end
