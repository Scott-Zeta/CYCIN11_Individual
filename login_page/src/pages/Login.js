import { StyledTextInput, StyledFormArea, StyledFormButton, StyledLabel, Avatar, StyledTitle, colors } from './../components/Styles'

import Logo from './../assets/logo.svg';

//formik
import { Formik, Form } from 'formik'
import { TextInput } from '../components/FormLib';

const Login = () => {
    return (
        <div>
            <StyledFormArea>
                <Avatar image={Logo} />
                <StyledTitle color={colors.theme} size={30}>
                    Member Login
                </StyledTitle>
                <Formik>
                    {() => (
                        <Form>
                            <TextInput 
                                name = "email"
                                type = "text"
                                label = "Email Address"
                                placeholde = "address@example.com"
                            />
                        </Form>
                    )}
                </Formik>
            </StyledFormArea>
        </div>
    )
}

export default Login;