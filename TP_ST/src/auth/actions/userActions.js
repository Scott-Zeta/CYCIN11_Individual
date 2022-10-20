import axios from 'axios';

import { sessionService } from 'redux-react-session';

export const loginUser = (credentials, history, setFieldError, setSubmitting) => {
    //Make checks and get some data
    axios.post("https://evening-woodland-35500.herokuapp.com/user/signin",
        credentials,
        {
            headers: {
                "Context-Type": "application/json"
            }
        }
    ).then((response) => {
        //take out data from the response
        const { data } = response;
        if (data.status === "FAILED") {
            const { message } = data;

            //check for specific error
            if (message.includes("credentials")) {
                setFieldError("email", message);
                setFieldError("password", message);
            } else if (message.includes("password")) {
                setFieldError("password", message);
            }
        } else if (data.status === "SUCCESS") {
            const userData = data.data[0];

            const token = userData._id;

            sessionService.saveSession(token).then(() => {
                sessionService.saveUser(userData).then(() => {
                    //history.push("/dashboard");
                    history("/dashboard")
                }).catch(err => console.error(err))
            }).catch(err => console.error(err))
        }
        //complete submission
        setSubmitting(false);

    }).catch(err => console.error(err))

}

export const signupUser = (credentials, history, setFiledError, setSubmitting) => {

}

export const logoutUser = () => {

}