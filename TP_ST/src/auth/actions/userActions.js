import axios from 'axios';

export const loginUser = (credentials, history, setFiledError, setSubmitting) => {
    //Make checks and get some data
    axios.post("https://evening-woodland-35500.herokuapp.com/user/signin",
    credentials,
    {
        headers:{
            "Context-Type": "application/json"
        }
    }
    ).then((response) =>{
        //take out data from the response
        
    }).catch(err => console.error(err))


    const user = {
        name: "Zeta",
        "email": "wc@gmail.com"
    }
    const status = true;

    if (status === true) {
        //allow
    } else {
        //deny
    }
}

export const signupUser = (credentials, history, setFiledError, setSubmitting) => {

}

export const logoutUser = () => {

}