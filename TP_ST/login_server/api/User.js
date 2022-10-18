const express = require('express');
const router = express.Router()

//signup
router.post('/signup', (req,res) =>{
    let {name, email, password, dateofBirth} = req.body;
    //trim for remove whithe space
    name = nmae.trim();
    email = email.trim();
    password = password.trim();
    dateofBirth = dateofBirth.trim();

    if(name == "" || email == "" || password == "" || dateofBirth == ""){
        res.json({
            status: "FAILED",
            message: "Empty fields!"
        })
    }else if(!/^[a-zA-Z]*$/.test(name)){
        res.json({
            status: "FAILED",
            message: "Invalid name"
        })
    }else if(!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(email)){
        res.json({
            status: "FAILED",
            message: "Invalid email"
        })
    }else if (!new Date(dateofBirth).getTime()){
        res.json({
            status: "FAILED",
            message: "Invalid date of birth"
        })
    }else if(password.lenth < 8){
        res.json({
            status: "FAILED",
            message: "Password too short"
        })
    } else {
        //check if user already exists
        
    }
})

//login
router.post('/signin', (req, res) => {

})

module.exports = router;