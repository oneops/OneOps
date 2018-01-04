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
public class MdUpdateRelation extends AbstractRoutine<java.lang.Void> {

    private static final long serialVersionUID = 1842488922;

    /**
     * The parameter <code>kloopzcm.md_update_relation.p_rel_id</code>.
     */
    public static final Parameter<Integer> P_REL_ID = createParameter("p_rel_id", org.jooq.impl.SQLDataType.INTEGER, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_relation.p_rel_name</code>.
     */
    public static final Parameter<String> P_REL_NAME = createParameter("p_rel_name", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_relation.p_short_rel_name</code>.
     */
    public static final Parameter<String> P_SHORT_REL_NAME = createParameter("p_short_rel_name", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * The parameter <code>kloopzcm.md_update_relation.p_descr</code>.
     */
    public static final Parameter<String> P_DESCR = createParameter("p_descr", org.jooq.impl.SQLDataType.VARCHAR, false, false);

    /**
     * Create a new routine call instance
     */
    public MdUpdateRelation() {
        super("md_update_relation", Kloopzcm.KLOOPZCM);

        addInParameter(P_REL_ID);
        addInParameter(P_REL_NAME);
        addInParameter(P_SHORT_REL_NAME);
        addInParameter(P_DESCR);
    }

    /**
     * Set the <code>p_rel_id</code> parameter IN value to the routine
     */
    public void setPRelId(Integer value) {
        setValue(P_REL_ID, value);
    }

    /**
     * Set the <code>p_rel_name</code> parameter IN value to the routine
     */
    public void setPRelName(String value) {
        setValue(P_REL_NAME, value);
    }

    /**
     * Set the <code>p_short_rel_name</code> parameter IN value to the routine
     */
    public void setPShortRelName(String value) {
        setValue(P_SHORT_REL_NAME, value);
    }

    /**
     * Set the <code>p_descr</code> parameter IN value to the routine
     */
    public void setPDescr(String value) {
        setValue(P_DESCR, value);
    }
}
