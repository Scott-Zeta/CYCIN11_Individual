//can not access dash borad without login

import { Route, Navigate } from "react-router-dom";
import { connect } from 'react-redux';

const BasicRoute = ({ children, authenticated, ...rest }) => {
    return (
        <Route
            {...rest}
            render={
                ({ location }) => !authenticated ? (children) : (
                    <Navigate
                        to={{
                            pathname: "/dashboard",
                            state: { from: location }
                        }}
                    />
                )
            }
        />
    )
}

const mapStateToProps = ({ session }) => ({
    authenticated: session.authenticated
})

export default connect(mapStateToProps)(BasicRoute);