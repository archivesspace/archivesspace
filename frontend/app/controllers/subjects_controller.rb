class SubjectsController < ApplicationController

   def index
      @subjects = Subject.all
   end

   def list
      @subjects = Subject.all

      if params[:q]
         @subjects = @subjects.select {|s| s.display_string.downcase.include?(params[:q].downcase)}
      end

      respond_to do |format|
          format.json {
             render :json => @subjects
          }
        end
   end

   def show
     @subject = Subject.find(params[:id])
   end

   def new
      @subject = Subject.new({:vocab_id => JSONModel(:vocabulary).id_for(session[:vocabulary]["uri"])})._always_valid!
      render :partial=>"subjects/new" if inline?
   end

   def edit
      @subject = Subject.find(params[:id])
   end

   def create
      begin
         @subject = Subject.new(params[:subject])

         if not params.has_key?(:ignorewarnings) and not @subject._exceptions.empty?
            return render :partial=>"subjects/new" if inline?
            return render :action => :new
         end

         id = @subject.save

         return render :json => @subject.to_hash if inline?

         redirect_to :controller=>:subjects, :action=>:show, :id=>id
      rescue JSONModel::ValidationException => e
        render :action => :new
      end
   end

   def update
     @subject = JSONModel(:subject).find(params[:id])
     begin
         @subject.replace(params[:subject])

         if not params.has_key?(:ignorewarnings) and not @subject._exceptions.empty?
            return render :action => :edit
         end
    
         result = @subject.save

         flash[:success] = "Collection Saved"         
         render :action => :show
     rescue JSONModel::ValidationException => e
         render :action=> :edit
     end
   end
   
end
