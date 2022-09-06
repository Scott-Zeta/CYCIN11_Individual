import { StyledTextInput, StyledFormArea, StyledFormButton, StyledLabel, Avatar, StyledTitle, colors, ButtonGroup } from './../components/Styles'

import Logo from './../assets/logo.svg';

//formik
import { Formik, Form } from 'formik'
import { TextInput } from '../components/FormLib';
import * as Yup from 'yup';

//icons
import { FiMail, FiKey } from "react-icons/fi";

const Login = () => {
    return (
        <div>
            <StyledFormArea>
                <Avatar image={Logo} />
                <StyledTitle color={colors.theme} size={30}>
                    Member Login
                </StyledTitle>
                <Formik
                    initialValues={{
                        email: "",
                        password: "",
                    }}

                    //validation
                    validationSchema = {
                        Yup.object({
                            email: Yup.string().email("Invalid email address")
                            .required("Required"),
                            password: Yup.string()
                            .min(8, "Too short password")
                            .max(30, "Too long password")
                            .required("Required"),
                        })
                    }

                    onSubmit={(values, { setSubmitting }) => {
                        console.log(values);
                    }}
                >
                    {() => (
                        <Form>
                            <TextInput
                                name="email"
                                type="text"
                                label="Email Address"
                                placeholder="address@example.com"
                                icon={<FiMail />}
                            />
                            <TextInput
                                name="password"
                                type="password"
                                label="Password"
                                icon={<FiKey />}
                            />
                            <ButtonGroup>
                                <StyledFormButton type="submit">
                                    Login
                                </StyledFormButton>
                            </ButtonGroup>
                        </Form>
                    )}
                </Formik>
            </StyledFormArea>
        </div>
    )
}

export default Login;