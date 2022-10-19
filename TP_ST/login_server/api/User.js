const express = require('express');
const router = express.Router()

//mongodb user model
const User = require('./../models/User');

//Password handler
const bcrypt = require('bcrypt');

//signup
router.post('/signup', (req, res) => {
    let { name, email, password, dateOfBirth } = req.body;
    //trim for remove whithe space
    name = name.trim()
    email = email.trim()
    password = password.trim()
    dateOfBirth = dateOfBirth.trim()

    if (name == "" || email == "" || password == "" || dateOfBirth == "") {
        res.json({
            status: "FAILED",
            message: "Empty fields!"
        })
    } else if (!/^[a-zA-Z]*$/.test(name)) {
        res.json({
            status: "FAILED",
            message: "Invalid name"
        })
    } else if (!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(email)) {
        res.json({
            status: "FAILED",
            message: "Invalid email"
        })
    } else if (!new Date(dateOfBirth).getTime()) {
        res.json({
            status: "FAILED",
            message: "Invalid date of birth"
        })
    } else if (password.lenth < 8) {
        res.json({
            status: "FAILED",
            message: "Password too short"
        })
    } else {
        //check if user already exists
        User.find({ email }).then(result => {
            if (result.length) {
                //user already exists
                res.json({
                    status: "FAILED",
                    message: "User with the provide email already exists"
                })
            } else {
                //try create new user

                //password handling
                const saltRounds = 10;
                bcrypt.hash(password, saltRounds).then(hashedPassword => {
                    const newUser = new User({
                        name,
                        email,
                        password: hashedPassword,
                        dateOfBirth
                    });

                    newUser.save().then(result => {
                        res.json({
                            status: "SUCCESS",
                            message: "Signup successful!",
                            data: result,
                        })
                    })
                        .catch(err => {
                            res.json({
                                status: "FAILED",
                                message: "error occurred while Saving the User Account"
                            })
                        })
                })
                    .catch(err => {
                        res.json({
                            status: "FAILED",
                            message: "error occurred while hashing password"
                        })
                    })
            }
        }).catch(err => {
            console.log(err);
            res.json({
                status: "FAILED",
                message: "error occurred while checking for existing user"
            })
        })
    }
})

//login
router.post('/signin', (req, res) => {
    let { email, password } = req.body;
    email = email.trim()
    password = password.trim()

    if (email == "" || password == "") {
        res.json({
            status: "FAILED",
            message: "Empty credentials supplied"
        })
    } else {
        //check if user exist
        User.find({ email })
            .then(data => {
                if (data) {
                    const hashedPassword = data[0].password;
                    bcrypt.compare(password, hashedPassword).then(result => {
                        if (result) {
                            res.json({
                                status: "SUCCESS",
                                message: "Signin Successful",
                                data: data
                            })
                        } else {
                            res.json({
                                status: "FAILED",
                                message: "Invalid password entered"
                            })
                        }
                    })
                        .catch(err => {
                            res.json({
                                status: "FAILED",
                                message: "Error while verify"
                            })
                        })
                } else {
                    res.json({
                        status: "FAILED",
                        message: "Invalid credentials entered"
                    })
                }
            })
            .catch(err => {
                res.json({
                    status: "FAILED",
                    message: "Error occureed while checking for exisiting user"
                })
            })
    }
})

module.exports = router;