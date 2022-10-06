//pages components
import Home from './pages/Home';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Dashboard from './pages/Dashboard';

// sub-pages in rider
import RiderList from './pages/RiderList';

//styled components
import { StyledContainer } from './components/Styles';

import {
  BrowserRouter as Router,
  Routes, Route
} from 'react-router-dom';

function App() {
  return (
    <Router>
      <StyledContainer>
        <Routes>
          <Route path='/login' element={<Login />}/>
          <Route path='/signup' element={<Signup />}/>
          <Route path='/dashboard' element = {<Dashboard />}/>
          <Route path='/' element = {<Home />}/>

        </Routes>
      </StyledContainer>
    </Router>
  );
}

export default App;
