class UserController < ApplicationController
  def login
    if(params[:error] == '1')
      @errorMsg = String.new("Please enter a valid login name and password")

    elsif(params[:error] == '2')
      @errorMsg = String.new("You have succesfully logged out")
    else
      @errorMsg = ""
    end
  end

  def post_login
    user = User.find_by_login(params[:login])

    if (user != nil && params[:password] != "")

      pass_str = String.new(params[:password] + user.salt.to_s)
      password_digest = Digest::SHA1.hexdigest(pass_str)

      if (user.password_digest == password_digest)
        session[:user_id] = user.id
        redirect_to(:controller=> :pics, :action => :user, :id=>user.id)
      else
        redirect_to(:action => "login", :error => '1')
      end
    else
      redirect_to(:action => "login", :error => '1')

    end
  end

  def post_logout
    session[:user_id] = nil
    redirect_to(:action => :login , :error => '2')
  end

  def logout
    session[:user_id] = nil
    redirect_to(:action => :login , :error => '2')
  end

  def register
    @errors = Array.new
    usr = User.new
  end

  def post_register
    @errors = Array.new
    if((params[:user][:password] == "") || (params[:user][:re_password] == "") || (params[:user][:first_name] == "") || (params[:user][:last_name] == "") || (params[:user][:login] == ""))  then
      @errors << "Please fill all the fields to register"

    elsif  params[:user][:password] != params[:user][:re_password] then
      @errors << "Password: please enter the same password in both password boxes"
    else
      salt =  rand(100)
      pass_str = String.new(params[:user][:password] + salt.to_s)
      password_digest = Digest::SHA1.hexdigest(pass_str)
      usr = User.new
      usr.first_name = params[:user][:first_name]
      usr.last_name = params[:user][:last_name]
      usr.password_digest = password_digest
      usr.login = params[:user][:login]
      usr.salt = salt
      usr.save(:validate => true)
      @errors = usr.errors.full_messages
    end
    if(@errors.length == 0) then
      redirect_to(:action => :login, :errors => " You have Successfuly Registered. Login to access your account")
    else
      redirect_to(:action => :register, :errors => @errors)
    end
  end

  def unregister
    @errors = Array.new

  end

  def post_unregister
    @errors = Array.new
    if((params[:user][:password] == "") || (params[:user][:re_password] == "") || (params[:user][:login] == ""))  then
      @errors << "Please fill all the fields to unregister"
      redirect_to(:action => :unregister, :errors => @errors)
    elsif  params[:user][:password] != params[:user][:re_password] then
      @errors << "Password: please enter the same password in both password fields"
      redirect_to(:action => :unregister, :errors => @errors)
    else

      user = User.find_by_login(params[:user][:login])

      if (user != nil && params[:user][:password] != "")

        pass_str = String.new(params[:user][:password] + user.salt.to_s)
        password_digest = Digest::SHA1.hexdigest(pass_str)

        if (user.password_digest == password_digest)

          tagges = Tagger.find_all_by_user_id(user.id)
          if(tagges != nil)
            tagges.each do |thisTag|
              thisTag.destroy()
            end
          end

          photos = Photo.find_all_by_user_id(user.id)
          if(photos != nil)
            photos.each do |thisPhoto|
              deletePhoto(thisPhoto.id);

            end
          end

          friends = Friend.find_all_by_fav_id(user.id)
          if(friends.length > 0)
            friends.each do |friend|
              friend.destroy()
            end
          end

          friends = Friend.find_all_by_user_id(user.id)
          if(friends.length > 0)
            friends.each do |friend|
              friend.destroy()
            end
          end

          comments = Comment.find_by_user_id(user.id)
          if (comments != nil) then
          comments.destroy()
          end
          user.destroy()
          session[:user_id] = nil
          redirect_to(:action => :index)
        else
          @errors << "Password: This password is incorrect"
          redirect_to(:action => :unregister, :errors => @errors)
        end
      elsif(user == nil)
        @errors << "Password: This user ID is incorrect"
        redirect_to(:action => :unregister, :errors => @errors)
      end
    end
  end

  def deletePhoto(photoID)
    comments = Comment.find_by_photo_id(photoID)
    if (comments != nil) then
    comments.destroy()
    end

    photo= Photo.find_by_id(photoID)

    File.delete("public/images/" + photo.file_name)
    tagges = Tagger.find_all_by_photo_id(photoID)
    if(tagges != nil)
      tagges.each do |thisTag|
        thisTag.destroy()
      end
    end

    photo.destroy()
  end

end