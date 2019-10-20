class MultiIO
  def initialize(ios)
    @ios = ios
  end

  def write(*args)
    @ios.each{|io| io.write(*args)}
  end

  def close
    @ios.each(&:close)
  end
end

class MultiMsg

  def initialize(production, &block)
    @production = production
    @senders    = block
  end

  def send(title, msg)
    @senders.call(title, msg) if @production
  end

end
