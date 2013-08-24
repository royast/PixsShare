class PicsController < ApplicationController
  def removeTag
    thisTag = Tagger.find(:all, :conditions =>{ :user_id => params[:id] , :photo_id => params[:picId]})
    thisTag[0].destroy()
    redirect_to(:action => "user", :id => params[:pageId], :anchor=>'pic'+params[:picId])
  end

  def users
    loggedUsr
    @userArr = Array.new
    i = 0
    User.find_each do |thisUser|
      @userArr[i] = {:first => thisUser.first_name, :last => thisUser.last_name, :id => thisUser.id, :loginInfo => thisUser.login}
      i = i + 1
    end
  end

  def user
    loggedUsr
    @comment = Comment.new

    #find the user who's page is being shown
    @user = String.new
    @user = User.find_by_id(params[:id]).first_name + " " + User.find_by_id(params[:id]).last_name
    @picsArr = Array.new
    @picsArrTagged = Array.new
    i = 0
    Photo.find_each do |thisPic|
      if(thisPic.user_id.to_i == params[:id].to_i )
        thisUser = User.find_by_id(thisPic.user_id)
        firstName = thisUser.first_name
        lastName = thisUser.last_name
        commArr = Array.new
        picComments = Comment.where("photo_id = ?", thisPic.id)

        j = 0
        picComments.find_each do |thisComment|
          commentUser = User.find_by_id(thisComment.user_id)
          comFirstName = commentUser.first_name
          comLastName = commentUser.last_name
          commArr[j] = {:comment => thisComment.comment, :comFirst => comFirstName, :comLast => comLastName, :id => thisComment.user_id, :time => thisComment.date_time, :commId =>thisComment.id}
          j = j + 1
        end

        @picsArr[i] = {:id=> thisPic.id, :usr_id => thisPic.user_id, :time => thisPic.date_time, :last_name => lastName, :first_name => firstName, :file => thisPic.file_name, :comment => commArr}
      i = i + 1
      end
    end

    i = 0
    j = 0
   
    tagges = Tagger.find_all_by_user_id(params[:id])
    if(tagges != nil)
      tagges.each do |thisTag|
        thisPic = Photo.find_by_id(thisTag.photo_id)
        thisUser = User.find_by_id(thisPic.user_id)
        firstName = thisUser.first_name
        lastName = thisUser.last_name
        commArr = Array.new
        picComments = Comment.where("photo_id = ?", thisPic.id)

        j = 0
        picComments.find_each do |thisComment|
          commentUser = User.find_by_id(thisComment.user_id)
          comFirstName = commentUser.first_name
          comLastName = commentUser.last_name
          commArr[j] = {:comment => thisComment.comment, :comFirst => comFirstName, :comLast => comLastName, :id => thisComment.user_id, :time => thisComment.date_time,  :commId =>thisComment.id}
          j = j + 1
        end

        @picsArrTagged[i] = {:id=> thisPic.id, :usr_id => thisPic.user_id, :time => thisPic.date_time, :last_name => lastName, :first_name => firstName, :file => thisPic.file_name, :comment => commArr}
        i = i + 1
      end
    end

  end

  def loggedUsr
    #Check to see if a user is logged in
    @sessionId = session[:user_id]
    if(@sessionId != nil) then
      @loggedUsr = User.find_by_id(@sessionId).first_name
    else
      @loggedUsr = nil
    end
  end

  def comment

    loggedUsr
    if session[:user_id].nil?
      redirect_to(:controller=> :user, :action => :login)
    end

  end

  def post_comment
    loggedUsr
    if session[:user_id].nil?
      redirect_to(:controller=> :user, :action => :login)
    return
    end

    pic = Photo.find_by_id(params[:id])
    @comment = Comment.new
    @comment.user_id = session[:user_id]
    @comment.photo_id = params[:id]
    @comment.date_time = DateTime.now
    @comment.comment = params[:comment][:comment]
    @comment.save(:validate => true)
    @errors = @comment.errors.full_messages
    if (!params[:comment][:taggedIn].nil?) 
    redirect_to(:action => :user, :id=> params[:comment][:pageId], :anchor=>'pic' + params[:id], :errors => @errors,  :taggedIn =>params[:comment][:taggedIn])
    else
    redirect_to(:action => :user, :id=> params[:comment][:pageId], :anchor=>'pic' + params[:id], :errors => @errors) 
    end  
  end

  def post_photo

    #input_image_filename, output_image_filename, max_width, max_height

    photo=Photo.new
    photo.save

    uploaded = params[:photo]
    @errors = Array.new
    if (uploaded == nil) then
      @errors << "Please choose a file before attempting to upload"
      redirect_to(:action => :user, :id=> session[:user_id], :errors => @errors)
    return
    elsif (File.extname(uploaded[:image].original_filename())!= ".gif" &&
    File.extname(uploaded[:image].original_filename())!= ".png" &&
    File.extname(uploaded[:image].original_filename())!= ".jpeg" &&
    File.extname(uploaded[:image].original_filename())!= ".jpg" &&
    File.extname(uploaded[:image].original_filename())!= ".GIF" &&
    File.extname(uploaded[:image].original_filename())!= ".PNG" &&
    File.extname(uploaded[:image].original_filename())!= ".JPEG" &&
    File.extname(uploaded[:image].original_filename())!= ".JPG") then
      @errors << "Please choose a gif, png, jpeg or jpg format file"
      redirect_to(:action => :user, :id=> session[:user_id], :errors => @errors)
    return

    end

    File.open("public/images/" +photo.id.to_s+uploaded[:image].original_filename, "wb") do |file|
      file.write(uploaded[:image].read)
    end

    photo.date_time = DateTime.now
    photo.user_id = session[:user_id]
    photo.file_name = photo.id.to_s+uploaded[:image].original_filename
    photo.save

    @errors << "Photo uploaded successfully"
    redirect_to(:action => :user, :id=> session[:user_id], :errors => @errors, :anchor=>'pic'+ photo.id.to_s)
  end

 def delete_photo
    comments = Comment.find_by_photo_id(params[:id])
    if (comments != nil) then
    comments.destroy()
    end

    photo= Photo.find_by_id(params[:id])

    File.delete("public/images/" + photo.file_name)
    tagges = Tagger.find_all_by_photo_id(params[:id])
    if(tagges != nil)
      tagges.each do |thisTag|
        thisTag.destroy()
      end
    end

    photo.destroy()

    redirect_to(:action => :user, :id=> session[:user_id])
  end

  def createTag
    #Create the Select User form for tagging
       loggedUsr
    @userArr = Array.new
    i = 0
    User.find_each do |thisUser|
      @userArr[i] = {:first => thisUser.first_name, :last => thisUser.last_name, :id => thisUser.id, :loginInfo => thisUser.login}
      i = i + 1
    end
   


    @testForm = String.new
    usrForm = String.new
    fullName = String.new
    testForm = String.new

    testForm = "<option value='0'>Select a user to tag</option>"
    User.find_each do |thisUsr|
      fullName = thisUsr.first_name + " " + thisUsr.last_name
      testForm = testForm + "<option value='" + thisUsr.id.to_s + "'>" + fullName + "</option>"

    end

    @testForm = testForm.html_safe

  end

  def createTagForm

    if(params[:userId].to_i>0)

      oldTag = Tagger.find(:all, :conditions =>{ :user_id => params[:userId] , :photo_id => params[:pic]})
      if(oldTag.length>0)
        i = 0;
       while(i< oldTag.length)
         oldTag[i].destroy()
         i = i + 1
       end
      end

      tagger = Tagger.new
      tagger.x_cord=params[:x]
      tagger.y_cord=params[:y]
      tagger.photo_id=params[:pic]
      tagger.user_id=params[:userId]
    tagger.save
    
    end

  end

  def show_tags

  end

  def add_favs
    if (session[:user_id] != nil)

      friend = Friend.new
      friend.fav_id = params[:id]
      friend.user_id = session[:user_id]
      friend.save
      redirect_to(:action => :user, :id=> params[:id])
    else
      redirect_to(:controller=> :user, :action => :login)
    end
  end

  def delete_favs
    if (session[:user_id] != nil)
      friends = Friend.find(:all, :conditions =>{ :user_id => session[:user_id] , :fav_id => params[:id]})
      friends[0].destroy()
      redirect_to(:action => :user, :id=> params[:id])
    else
      redirect_to(:controller=> :user, :action => :login)
    end
  end

  def autocomplete

    if(params[:chars] == "")
      userArr2 = Array.new
      i = 0
      User.find_each do |thisUser|
        userArr2[i] = {:first => thisUser.first_name, :last => thisUser.last_name, :id => thisUser.id, :loginInfo => thisUser.login}
        i = i + 1
      end

      renderText = ""

      userArr2.each do |users|
        renderText << " <li> <p style='white-space: nowrap;'> <a style='color:navy;' href='/pics/user/" + users[:id].to_s + "'>" + users[:first]+ " " + users[:last] + " </a> </p> </li>  "
      end

      render :text => renderText
    else
      userArr = Array.new
      i = 0
    
      myRegExp = "\\A" + params[:chars] 
   
      User.find_each do |thisUser|
        fullname = thisUser.first_name + " " + thisUser.last_name
        myRegExp =Regexp.new(myRegExp, Regexp::IGNORECASE) 
        lastname = thisUser.last_name
        if(fullname.match(myRegExp) || lastname.match(myRegExp))
          
          userArr[i] = {:first => thisUser.first_name, :last => thisUser.last_name, :id => thisUser.id, :loginInfo => thisUser.login}
        i = i + 1
        end
      end
      renderText = ""
      userArr.each do |users|
        renderText << " <li> <p style='white-space: nowrap;'> <a style='color:navy;' href='/pics/user/" + users[:id].to_s + "'>" + users[:first]+ " " + users[:last] + " </a> </p> </li>  "
      end
      render :text => renderText
    end
  end

 def tagcomplete

    if(params[:chars] == "")
      userArr2 = Array.new
      i = 0
      User.find_each do |thisUser|
        userArr2[i] = {:first => thisUser.first_name, :last => thisUser.last_name, :id => thisUser.id, :loginInfo => thisUser.login}
        i = i + 1
      end

      renderText = ""

      userArr2.each do |users|
       fullName = users[:first].to_s + " " + users[:last].to_s
        renderText << " <li>  <a href='javascript:void(0)' onclick=\"fillForm(" + users[:id].to_s + ",'" + fullName + "')\">" + fullName + "</a></br></li>"

      end

      render :text => renderText
    else
      userArr = Array.new
      i = 0
    
      myRegExp = "\\A" + params[:chars] 
   
      User.find_each do |thisUser|
        fullname = thisUser.first_name + " " + thisUser.last_name
        myRegExp =Regexp.new(myRegExp, Regexp::IGNORECASE) 
        lastname = thisUser.last_name
        if(fullname.match(myRegExp) || lastname.match(myRegExp))
          
          userArr[i] = {:first => thisUser.first_name, :last => thisUser.last_name, :id => thisUser.id, :loginInfo => thisUser.login}
        i = i + 1
        end
      end
      renderText = ""
      userArr.each do |users|
         fullName = users[:first].to_s + " " + users[:last].to_s
        renderText << " <li>  <a href='javascript:void(0)' onclick=\"fillForm(" + users[:id].to_s + ",'" + fullName + "')\">" + fullName + "</a><br/> </li>"
  
      end
      render :text => renderText
    end
  end
 def remove_comment
    thisComment = Comment.find_by_id(params[:id])
    if(thisComment != nil)
      picId=thisComment.photo_id.to_s
    thisComment.destroy()
    redirect_to(:action => "user", :id => params[:pageId], :anchor=>'pic'+picId, :taggedIn =>params[:taggedIn])
    else
      redirect_to(:action => "user", :id => params[:pageId], :taggedIn =>params[:taggedIn])
    end
    
 end

end

