# frozen_string_literal: true

ENV["PATH"] = [__dir__, ENV.fetch("PATH", nil)].join(":")

job :pass do
  execute "job 0"
end

job :fail_1 do
  execute "job 1"
end

job :fail_42 do
  execute "job 42"
end

job :command_not_found do
  execute "command_not_found arg"
end
