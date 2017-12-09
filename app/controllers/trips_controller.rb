class TripsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index, :apriori, :result_apriori, :dbscan, :result_dbscan]
  before_action :authenticate_editor!, only: [:new, :create, :update]
  before_action :authenticate_admin!, only: [:destroy]

  before_action :set_trip, only: [:show, :edit, :update, :destroy]

  # GET /trips
  # GET /trips.json
  def index
    @trips = Trip.all
  end

  # GET /trips/1
  # GET /trips/1.json
  def show
  end

  # GET /trips/new
  def new
    @trip = Trip.new
  end

  # GET /trips/1/edit
  def edit
  end

  # POST /trips
  # POST /trips.json
  def create
    @trip = Trip.new(trip_params)

    respond_to do |format|
      if @trip.save
        format.html { redirect_to @trip, notice: 'Trip was successfully created.' }
        format.json { render :show, status: :created, location: @trip }
      else
        format.html { render :new }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trips/1
  # PATCH/PUT /trips/1.json
  def update
    respond_to do |format|
      if @trip.update(trip_params)
        format.html { redirect_to @trip, notice: 'Trip was successfully updated.' }
        format.json { render :show, status: :ok, location: @trip }
      else
        format.html { render :edit }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trips/1
  # DELETE /trips/1.json
  def destroy
    @trip.destroy
    respond_to do |format|
      format.html { redirect_to trips_url, notice: 'Trip was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def import
    Trip.import(params[:file])
    redirect_to root_path
  end

  def apriori
      #@trip = Trip.search_user(params[:user_id])
      #render :inline =>
      #"<% @trip.each do |p| %><p><%= p.user_id %><p><% end %>"
  end

  def dbscan

  end

  def result_apriori
      @trip = Trip.search_user(params[:user_id])
      @user_id = params[:user_id]

      if @trip.present?
          @input_data = []
          @counter = 0
          @days = []
          @ports = []
          @total_ports = []
          @trip.each do |trip|
              unless @days.include? trip.start_trip.to_date
                  @days.push(trip.start_trip.to_date) 
              end
          end

          @trip.each do |trip|
              if trip.start_trip.to_date == @days[@counter]
                  @ports.push(trip.origin_id) 
                  @ports.push(trip.destination_id) 
              else
                  @total_ports[@counter] = @ports
                  @ports = []
                  @ports.push(trip.origin_id) 
                  @ports.push(trip.destination_id)
                  @counter += 1
              end
          end

          @last_trip = []
          @trip.each do |trip|
              if trip.start_trip.to_date == @days.last
                  @last_trip.push(trip.origin_id)
                  @last_trip.push(trip.destination_id)
              end
          end
          @total_ports.push(@last_trip)

          0.upto(@days.length - 1) do |i|
              @input_data[i] = [@days[i], @total_ports[i]]
          end



          min_support  = 2
          @apriori = DataMining::Apriori.new(@input_data, min_support)
          @apriori.mine!

          @result = @apriori.item_sets_size(2)
          @result.append([0,0])
          @result = @result.map{ |l|{x: l[0].to_i, y: l[1].to_i} }
          @result = @result.to_json
          @result = @result.to_s
          @result.delete! '\"'
      else
          render :inline =>
          "There's no a user with that ID"
      end
  end

  def result_dbscan
      @trips_result = Trip.select("id",params[:data1], params[:data2])
    
      @input_data = []
      numero = 0 
      @dato1 = 0
      @dato2 = 0 
      @iter = Trip.count
      @attribute1 = params[:data1]
      @attribute2 = params[:data2] 
      @graphic = params[:chart]  
      
      @trips_result.each do |trip|
          @dato1 = trip[params[:data1]]
          @dato2 = trip[params[:data2]]
          if params[:data1] == "start_trip" || params[:data1] == "end_trip" 
              splited1 = trip[params[:data1]]
              splited1 = splited1.to_s
              splited1 = splited1.split(" ")
              splited1 = splited1[1]
              splited1 = splited1.split(":")
              @dato1 = splited1[0].to_i
          end    
          if params[:data2] == "start_trip" || params[:data2] == "end_trip" 
              splited2 = trip[params[:data2]]
              splited2 = splited2.to_s
              splited2 = splited2.split(" ")
              splited2 = splited2[1]
              splited2 = splited2.split(":")
              @dato2 = splited2[0].to_i   
          end 
          if params[:data1] == "age" 
              @dato1 = 2017 - trip[params[:data1]]
          end 
          if params[:data2] == "age" 
              @dato2 = 2017 - trip[params[:data2]]
          end 
          if @dato1 == "M"
            @dato1 = 1
          end 
          if @dato2 == "M"
              @dato2 = 1
          end
          if @dato1 == "F"
            @dato1 = 0
          end 
          if @dato2 == "F"
              @dato2 = 0
          end
          
          @input_data[numero] = [trip.id, [@dato1,@dato2]]
          numero += 1
      end  
        
      radius = 0
      min_points = 2
      dbscan = DataMining::DBScan.new(@input_data, radius, min_points)
      dbscan.cluster!

      @all_clusters= dbscan.all_clusters
      @num_elements_in_clusters = dbscan.num_elements_in_clusters
      @total_clusters = dbscan.total_clusters  
      @outliner =  dbscan.outliers # gives point3 as outlie
      @all_clusters_clean = []
      @outliner_clean = [] 
      @num_elements_in_clusters_clean = []
      @ordered_data = []  
  
      ##Para eliminar los clusters erroneos
      cont = 0
      i = 0  
      @all_clusters.each do |value|
          if value.length == 2 
              @all_clusters_clean[i] = value
              @num_elements_in_clusters_clean[i] = @num_elements_in_clusters[cont] 
              i += 1
          end  
          cont += 1
      end  
      
    #indexa el arreglo de num elements in cluster para posteriormente realizar el ordenamiento por pesos
      i = 0  
      @num_elements_in_clusters_clean.each_with_index { |val, index|
            @ordered_data[i]= [val, index]
            i +=1
          }
      
      ##Para eliminar los datos atipicos erroneos
      cont = 0
      i = 0  
      @outliner.each do |value|
          if value != nil
              if value.length == 2 
                  @outliner_clean[i] = value
                  i += 1
              end  
              cont += 1
          end    
      end 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trip
      @trip = Trip.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trip_params
      params.require(:trip).permit(:genere, :age, :start_trip, :end_trip, :origin_id, :destination_id, :user_id)
    end

    def validate_user
        redirect_to new_user_session_path, notice: "You must log in before."
    end
end
