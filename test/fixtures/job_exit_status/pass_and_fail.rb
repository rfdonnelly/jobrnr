# frozen_string_literal: true

job :pass do
  execute "true"
end

job :fail do
  execute "false"
end
