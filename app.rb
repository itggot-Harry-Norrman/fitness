class App < Sinatra::Base

	enable :sessions

	get('/') do
		db = SQLite3::Database.new("db/db.db")
		slim(:index, locals:{msg: session[:msg]})
	end
	
	post('/register') do
		db = SQLite3::Database.new("db/db.db")
		username = params[:username]
		password = BCrypt::Password.create( params[:password] )
		password2 = BCrypt::Password.create( params[:password2] )
		
		if username == "" || password == "" || password == ""
			session[:msg] = "Please enter a username and password."
		elsif params[:password] != params[:password2]
			session[:msg] = "Passwords don't match"
		elsif db.execute("SELECT user FROM user_data WHERE user=?", username) != []
			session[:msg] = "Username already exists"
		else
			db.execute("INSERT INTO user_data ('user', 'password') VALUES (?,?)", [username, password])
		end
		redirect('/')
	end

	post('/login') do
		db = SQLite3::Database.new("db/db.db")
		username = params[:username]
		password = params[:password]
		if username == "" || password == ""
			session[:msg] = "Please enter a username and a password."
			redirect('/')
		else
			db_password = db.execute("SELECT password FROM user_data WHERE user=?", username)
			if db_password == []
				session[:msg] = "Username doesn't exist"
				redirect('/')
			else
				db_password = db_password[0][0]
				password_digest =  db_password
				password_digest = BCrypt::Password.new( password_digest )

				if password_digest == password
					user_id = db.execute("SELECT id FROM user_data WHERE user=?", username)
					user_id = user_id[0][0]
					session[:user_id] = user_id
					redirect('/user')
				else
					session[:user_id] = nil
					session[:msg] = "Wrong password or username"
					redirect('/')
				end
			end
		end
	end

	get('/user') do
		db = SQLite3::Database.new("db/db.db")
		if session[:user_id]
			ovningar = db.execute("SELECT ovning, reps, sets, day, id FROM ovningar WHERE user_id=?", session[:user_id])
			username = db.execute("SELECT user FROM user_data WHERE id=?", session[:user_id])
			slim(:user, locals:{ovningar: ovningar, username:username})
		else 
			session[:msg] = "Login or register to access this page."
			redirect('/')
		end
	end
	post('/add_exercise') do
		db = SQLite3::Database.new("db/db.db")
		user_dat = params[:ovning]
		reps = params[:reps]
		sets = params[:sets]
		day = params[:day]
		db.execute("INSERT INTO ovningar ('ovning', 'reps', 'sets', 'day', 'user_id') VALUES (?,?,?,?,?)", [user_dat, reps, sets, day, session[:user_id]])
		redirect('/user')
	end
	get('/delete_exercise/:id') do
		db = SQLite3::Database.new("db/db.db")		
		db.execute("DELETE FROM ovningar WHERE id=?", params[:id])
		redirect('/user')
	end
	post('/logout') do
		session[:user_id] = nil
		redirect('/')
	end
	get('/main') do
		db = SQLite3::Database.new("db/db.db")
		if session[:user_id]
			ovningar = db.execute("SELECT ovning, reps, sets, day, id FROM ovningar WHERE user_id=?", session[:user_id])
			username = db.execute("SELECT user FROM user_data WHERE id=?", session[:user_id])
			slim(:mainsite, locals:{ovningar: ovningar, username:username})
		else 
			session[:msg] = "Login or register to access this page."
			redirect('/')
		end
	end
end           

