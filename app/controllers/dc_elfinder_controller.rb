#coding: utf-8
#--
# Copyright (c) 2012-2013 Damjan Rems
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
##########################################################################
#
##########################################################################
#require 'el_finder/action'

class DcElfinderController < DcApplicationController

skip_before_action :verify_authenticity_token # otherwise it fails on post because of protect_from_forgery
##########################################################################
# elfinder file manager connector
##########################################################################
def connector
  site = dc_get_site
  home_dir = File.join('/',site.files_directory)
# it is convenient for admin to have access to root dir directly
  if dc_user_has_role('admin') then home_dir = File.join('/',home_dir.split('/')[1]) 
  else
    user = DcUser.find(session[:user_id])
    home_dir = File.join('/', user.root_folder) if user.respond_to?(:root_folder) and !user.root_folder.blank?
  end
  h, r = ElFinder::Connector.new(
    :root => File.join(Rails.public_path, home_dir),
    :url  => home_dir,
    :perms => { '.' => { :read => true, :write => true,  :rm => true }},
      :extractors => { 
        'application/zip' => ['unzip', '-qq', '-o'], # Each argument will be shellescaped (also true for archivers)
        'application/x-gzip' => ['tar', '-xzf'],
      },
      :archivers => { 
        'application/zip' => ['.zip', 'zip', '-qr9'], # Note first argument is archive extension
        'application/x-gzip' => ['.tgz', 'tar', '-czf'],
        },
      :user_roles => session[:user_roles]
  ).run(params)
  headers.merge!(h)
  render (r.empty? ? {:nothing => true} : {:plain => r.to_json}), :layout => false
end

end
