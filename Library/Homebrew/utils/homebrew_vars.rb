#!/usr/bin/env ruby

ENV.keys.each do |key| 
  if key =~ /^HOMEBREW.*/
    # Remove any HOMEBREW.* vars containing white-space which causes a problem for "env -i" command via string.
    #
    # (Any user supplied HOMEBREW.* vars with valid white-space need to be hard-coded in 'bin/brew')
    #
    puts "#{key}=#{ENV[key]}" unless ENV[key].split(' ').length > 1
  end
end
