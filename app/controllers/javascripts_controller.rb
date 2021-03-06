# Javascript code controller 

class JavascriptsController < ApplicationController

  def hostname_check
 
    
    
  end

  # The main javascript tracker function, at the moment it's basically
  # taken from piwik.org. It registers the visitor informations and pass it
  # to log
  def piwik
  
    # see the views/javascripts/piwik.js.erb 
    
  end
  
  
  def log
      
 
      
      if session[:user_id]
        # User (not the visitor) is logged in..we dont count his actions
        puts ">>>>>>>>>>>>>>>> USER LOGGED IN, ACTIONS not counted"
        render :text => ""
      else
        
        project_id = params[:idsite]

        if (session[:project_id]) and (project_id != session[:project_id])
        # This visitor has already a session open, but using another project
          session[:visitor_id] = nil
        end

        session[:project_id] = project_id


        p = Project.find(project_id) 

        # Check if the params[:idsite] correspond to the right hostname
        # because we dont want to record stats from other hosts

        hostname = URI.parse(params[:url]).host
        if hostname.match(p.name) 
          puts " >>>>>>>>>>>>>>>>>> HOSTNAME MATCHES with the correct project_id"
          visitor_settings = Tracker.get_settings(params,request,p.name)  
          if session[:visitor_id]
            # Se c''e il visitor_id allora e' conosciuto
            # Vedo se l'ultima azione e' stata fatta in meno di mezzo'ora
            puts " >>>>>>>>>>>>>>>>> SESSION FOUND"
            v = Visitor.find(session[:visitor_id])
            if (Time.now - v.last_action_time) > 30.minutes
              # Sono passati piu' di 30 minuti, creo un nuovo visitor e lo metto come returning
              puts ">>>>>>>>>>>>>>>>>>>MORE THAN 30 minutes, create a new visitor"
              v = Visitor.create_with_settings(visitor_settings)
              p.visitors << v
              p.visitor_was_here!(v)
            end

          else

              puts ">>>>>>>>>>>>>>>>> NO SESSION"
              # There's no session, check if there was a visitor having the same browser configuration and IP today
              puts ">>>>>>>>>>> USER SETTINGS" + visitor_settings[:config_md5config]
              v = p.visitor_here_today?(visitor_settings)

              if v.nil? 
                puts ">>>>>>>>>>>> VISITOR NEW"
                # The visitor is new, create a new visitor and add him 
                v = Visitor.create_with_settings(visitor_settings)
                p.visitors << v
              else
                p ">>>>>>>>>>>> VISITOR HERE"

                if (Time.now - v.last_action_time) > 30.minutes
                  puts ">>>>>>>>>>>>>> MORE THAN 30 minutes, create new visitor"
                  # Sono passati piu' di 30 minuti, creo un nuovo visitor e lo metto come returning
                  v = Visitor.create_with_settings(visitor_settings)
                  p.visitors << v
                  p.visitor_was_here!(v)
                end

              end

          end

          session[:visitor_id] = v.id


          # Save the action only IF it's not already present.
          # Kind is used to distinguish between normal actions and goals
          # Other kinds should be used too, (such as downloads)

          # Clean the URL from the last '/'
          url = params[:url]
          if url.last == "/"
            url.chop!
          end

          action = Action.new(:url=>"#{url}", :url_id=> Digest::MD5.hexdigest(params[:url]),
                                   :kind => params[:action_kind].to_i) 
          # Add the action to the project, only if it's new
          # Return the old action if present
          a = p.add_action(action)  

          v.add_action(a)
        end
           
        
        
      end
      
       
   
     
  end

  
  def log_old
 
       
      project_id = params[:idsite]
      
      if (session[:project_id]) and (project_id != session[:project_id])
        ## This means the visitor has found another website using RUWA
        # Reset the visitor_id
        session[:visitor_id] = nil
      end
      
      session[:project_id] = project_id
      
  
      

      p = Project.find(project_id) 


      # Check if the params[:idsite] correspond to the right hostname
      # because we dont want to record stats from other hosts
      # Fix this code..it needs to work for www.hostname.com and hostname.com
      # hostname = URI.parse(params[:url]).host
      #       if p.name != hostname 
      #         render :text => ""
      #       end
      #       
      #       




      # If there's a session open, the visitor is known
      if session[:visitor_id]
        puts "SESSION FOUND, VISITOR KNOWN"
        v = Visitor.find(session[:visitor_id])
      else
        puts "NO SESSION"
        # There's no session, check if there was a visitor having the same browser configuration and IP today
        user_settings = Tracker.get_settings(params,request)  
        puts "USER SETTINGS" + user_settings[:config_md5config]
        v = p.visitor_here_today?(user_settings)
          
        if v.nil? 
          puts "VISITOR NEW"
          # The visitor is new, create a new visitor and add him to the project
          v = Visitor.create_with_settings(user_settings)
          p.visitors << v
        elsif (Time.now - v.last_action_time) > 30.minutes
          puts "VISITOR FOUND, but last action was more than 30 minutes ago"
          # The visitor was here, but more than 30 minutes ago, create a new visitor
           v = Visitor.create_with_settings(user_settings)
          p.visitors << v
        else
          # With no session, the visitor either cleared the cookies or restarted the browser...
          # I'll consider that as a returning visitor
            puts "RETURNING VISITOR"
            p.visitor_was_here!(v)
        
        end

        session[:visitor_id] = v.id
      end
      
     
      
      # Save the action only IF it's not already present.
      # Kind is used to distinguish between normal actions and goals
      # Other kinds should be used too, (such as downloads)
      
      # Clean the URL from the last '/'
      url = params[:url]
      if url.last == "/"
        url.chop!
      end
      
      action = Action.new(:url=>"#{url}", :url_id=> Digest::MD5.hexdigest(params[:url]),
                             :kind => params[:action_kind].to_i) 
    # Add the action to the project, only if it's new
    # Return the old action if present
     a = p.add_action(action)  

     v.add_action(a)
     
  end








  # THIS CODE IS NOT USED ANYMORE...


  # def log2
  #   project_id = params[:idsite]
  #   session[:project_id]  = project_id
  #   p = Project.find(project_id) 
  #   
  #   # Save the action
  #   # Kind is used to distinguish between normal actions and goals
  #   # Other kinds should be used too, (such as downloads)
  #   action = Action.create(:url=>"#{params[:url]}", :url_id=> Digest::MD5.hexdigest(params[:url]),
  #                          :kind => params[:action_kind].to_i)   
  #   
  #   
  #   # Check if the visitor has a session open
  #   if session[:visitor_id].nil?
  #     p "SESSION ID NOT FOUND"
  # 
  #     # There's no session, however we check if a visitor with the same settings
  #     # has already visited the website
  #     user_settings = Tracker.get_settings(params,request)           
  #     v = Visitor.here_today?(user_settings) # Check using user browser configuration + IP address
  #       
  #     if v.nil?
  #       p "VISITOR NEW TODAY"
  #       # There's no session id, and no visitor has been found. So we create a visitor
  #       v = Visitor.create_with_settings(user_settings)        
  #       p.visitors << v
  #     else
  #       p "VISITOR FOUND (he was here today)"
  #       v.was_here!
  #    
  #     end
  #   
  #     session[:visitor_id] = v.id
  #   else
  #     p "SESSION ID FOUND"
  #     v = Visitor.find(session[:visitor_id])
  #   end
  #   
  #   
  #  # v.actions << action
  #  v.add_action(action)
  #   
  # end
  #  

  


 
end
