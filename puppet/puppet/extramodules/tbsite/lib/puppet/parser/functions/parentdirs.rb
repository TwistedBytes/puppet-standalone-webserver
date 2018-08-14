# from: https://stackoverflow.com/questions/26433115/recursively-make-directory-tree-in-puppet-without-purging
module Puppet::Parser::Functions
  newfunction(:parentdirs, :type => :rvalue, :doc => <<-EOS
    Build a list of all its parent directories.
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "parentdirs(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    $dir_until = arguments.size > 1 ? arguments[1] : nil
    $cur = File.dirname(arguments[0])
    $result = []
    begin
        $result.unshift($cur)
        $last = $cur
        $cur = File.dirname($cur)
    end while $cur != $last and !$cur.end_with?('/') and $cur != $dir_until

    return $result
  end
end