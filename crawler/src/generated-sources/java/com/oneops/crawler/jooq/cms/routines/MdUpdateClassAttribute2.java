/*
 * This file is generated by jOOQ.
*/
package com.oneops.crawler.jooq.cms.routines;


import com.oneops.crawler.jooq.cms.Kloopzcm;

import javax.annotation.Generated;

import org.jooq.Parameter;
import org.jooq.impl.AbstractRoutine;


/**
 * This class is generated by jOOQ.
 */
@Generated(
    value = {
        "http://www.jooq.org",
        "jOOQ version:3.10.0"
    },
    comments = "This class is generated by jOOQ"
)
@SuppressWarnings({ "all", "unchecked", "rawtypes" })
public class MdUpdateClassAttribute2 extends AbstractRoutine<java.lang.Void> {

    private static final long serialVersionUID = -494178610;

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_attribute_id</code>.
     */
    public static final Parameter<Integer> P_ATTRIBUTE_ID = createParameter("p_attribute_id", org.jooq.impl.SQLDataType.INTEGER, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_attribute_name</code>.
     */
    public static final Parameter<String> P_ATTRIBUTE_NAME = createParameter("p_attribute_name", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_data_type</code>.
     */
    public static final Parameter<String> P_DATA_TYPE = createParameter("p_data_type", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_is_mandatory</code>.
     */
    public static final Parameter<Boolean> P_IS_MANDATORY = createParameter("p_is_mandatory", org.jooq.impl.SQLDataType.BOOLEAN, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_is_inheritable</code>.
     */
    public static final Parameter<Boolean> P_IS_INHERITABLE = createParameter("p_is_inheritable", org.jooq.impl.SQLDataType.BOOLEAN, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_is_encrypted</code>.
     */
    public static final Parameter<Boolean> P_IS_ENCRYPTED = createParameter("p_is_encrypted", org.jooq.impl.SQLDataType.BOOLEAN, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_is_immutable</code>.
     */
    public static final Parameter<Boolean> P_IS_IMMUTABLE = createParameter("p_is_immutable", org.jooq.impl.SQLDataType.BOOLEAN, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_force_on_dependent</code>.
     */
    public static final Parameter<Boolean> P_FORCE_ON_DEPENDENT = createParameter("p_force_on_dependent", org.jooq.impl.SQLDataType.BOOLEAN, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_default_value</code>.
     */
    public static final Parameter<String> P_DEFAULT_VALUE = createParameter("p_default_value", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_value_format</code>.
     */
    public static final Parameter<String> P_VALUE_FORMAT = createParameter("p_value_format", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_class_attribute.p_descr</code>.
     */
    public static final Parameter<String> P_DESCR = createParameter("p_descr", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * Create a new routine call instance
     */
    public MdUpdateClassAttribute2() {
        super("md_update_class_attribute", Kloopzcm.KLOOPZCM);

        addInParameter(P_ATTRIBUTE_ID);
        addInParameter(P_ATTRIBUTE_NAME);
        addInParameter(P_DATA_TYPE);
        addInParameter(P_IS_MANDATORY);
        addInParameter(P_IS_INHERITABLE);
        addInParameter(P_IS_ENCRYPTED);
        addInParameter(P_IS_IMMUTABLE);
        addInParameter(P_FORCE_ON_DEPENDENT);
        addInParameter(P_DEFAULT_VALUE);
        addInParameter(P_VALUE_FORMAT);
        addInParameter(P_DESCR);
        setOverloaded(true);
    }

    /**
     * Set the <code>p_attribute_id</code> parameter IN value to the routine
     */
    public void setPAttributeId(Integer value) {
        setValue(P_ATTRIBUTE_ID, value);
    }

    /**
     * Set the <code>p_attribute_name</code> parameter IN value to the routine
     */
    public void setPAttributeName(String value) {
        setValue(P_ATTRIBUTE_NAME, value);
    }

    /**
     * Set the <code>p_data_type</code> parameter IN value to the routine
     */
    public void setPDataType(String value) {
        setValue(P_DATA_TYPE, value);
    }

    /**
     * Set the <code>p_is_mandatory</code> parameter IN value to the routine
     */
    public void setPIsMandatory(Boolean value) {
        setValue(P_IS_MANDATORY, value);
    }

    /**
     * Set the <code>p_is_inheritable</code> parameter IN value to the routine
     */
    public void setPIsInheritable(Boolean value) {
        setValue(P_IS_INHERITABLE, value);
    }

    /**
     * Set the <code>p_is_encrypted</code> parameter IN value to the routine
     */
    public void setPIsEncrypted(Boolean value) {
        setValue(P_IS_ENCRYPTED, value);
    }

    /**
     * Set the <code>p_is_immutable</code> parameter IN value to the routine
     */
    public void setPIsImmutable(Boolean value) {
        setValue(P_IS_IMMUTABLE, value);
    }

    /**
     * Set the <code>p_force_on_dependent</code> parameter IN value to the routine
     */
    public void setPForceOnDependent(Boolean value) {
        setValue(P_FORCE_ON_DEPENDENT, value);
    }

    /**
     * Set the <code>p_default_value</code> parameter IN value to the routine
     */
    public void setPDefaultValue(String value) {
        setValue(P_DEFAULT_VALUE, value);
    }

    /**
     * Set the <code>p_value_format</code> parameter IN value to the routine
     */
    public void setPValueFormat(String value) {
        setValue(P_VALUE_FORMAT, value);
    }

    /**
     * Set the <code>p_descr</code> parameter IN value to the routine
     */
    public void setPDescr(String value) {
        setValue(P_DESCR, value);
    }
}
