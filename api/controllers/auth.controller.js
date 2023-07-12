const AuthService = require('../services/auth.service');
const createError = require('http-errors');

class AuthController {

    static validateEmail = (email) => {
      return String(email)
        .toLowerCase()
        .match(
          /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
        );
    }

    static register = async (req, res, next) => {
        try {
            const { name, email, password } = req.body
            if (!name || !email || !password || !this.validateEmail(email)) {
              throw {statusCode: 422, message: "invalid params"}
            }

            const user = await AuthService.register(req.body)
            user.speechKey = process.env.SPEECH_KEY
            user.speechRegion = process.env.SPEECH_REGION
            res.status(200).json({
                status: 0,
                message: 'User created successfully',
                data: user
            })

        }
        catch (e) {
            console.log(e)
            next(createError(e.statusCode, e.message))
        }
    }

    static login = async (req, res, next) => {
         try {
            const data = await AuthService.login(req.body)
            data.speechKey = process.env.SPEECH_KEY
            data.speechRegion = process.env.SPEECH_REGION
            res.status(200).json({
                status: 0,
                message: "Account login successful",
                data: data
            })
        } catch (e) {
            next(createError(e.statusCode, e.message))
        }
    }

    static all = async (req, res, next) => {
        try {
            const users = await AuthService.all();
            res.status(200).json({
                status: 0,
                message: 'All users',
                data: users
            })
        } catch (e) {
            next(createError(e.statusCode, e.message))
        }
    }
}

module.exports = AuthController