public class SAP_InstanceFactory {
    public static SAP_Instance getInstance(String instanceRegion){

        switch on instanceRegion{
            when 'NACA' {
                return new SAP_NACA();
            }
            when 'EMEA' {
                return new SAP_EMEA();
            }
            when else{
                throw new InstanceNotSupportedException('SAP Instance not supported');
            }
        }

    }

    public class InstanceNotSupportedException extends Exception {}

}