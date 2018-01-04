/*
 * This file is generated by jOOQ.
*/
package com.oneops.crawler.jooq.cms.tables.records;


import com.oneops.crawler.jooq.cms.tables.DjRfcCiAttributes;

import java.sql.Timestamp;

import javax.annotation.Generated;

import org.jooq.Field;
import org.jooq.Record1;
import org.jooq.Record8;
import org.jooq.Row8;
import org.jooq.impl.UpdatableRecordImpl;


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
public class DjRfcCiAttributesRecord extends UpdatableRecordImpl<DjRfcCiAttributesRecord> implements Record8<Long, Long, Integer, String, String, String, String, Timestamp> {

    private static final long serialVersionUID = 625868933;

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.rfc_attr_id</code>.
     */
    public void setRfcAttrId(Long value) {
        set(0, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.rfc_attr_id</code>.
     */
    public Long getRfcAttrId() {
        return (Long) get(0);
    }

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.rfc_id</code>.
     */
    public void setRfcId(Long value) {
        set(1, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.rfc_id</code>.
     */
    public Long getRfcId() {
        return (Long) get(1);
    }

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.attribute_id</code>.
     */
    public void setAttributeId(Integer value) {
        set(2, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.attribute_id</code>.
     */
    public Integer getAttributeId() {
        return (Integer) get(2);
    }

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.old_attribute_value</code>.
     */
    public void setOldAttributeValue(String value) {
        set(3, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.old_attribute_value</code>.
     */
    public String getOldAttributeValue() {
        return (String) get(3);
    }

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.new_attribute_value</code>.
     */
    public void setNewAttributeValue(String value) {
        set(4, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.new_attribute_value</code>.
     */
    public String getNewAttributeValue() {
        return (String) get(4);
    }

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.owner</code>.
     */
    public void setOwner(String value) {
        set(5, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.owner</code>.
     */
    public String getOwner() {
        return (String) get(5);
    }

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.comments</code>.
     */
    public void setComments(String value) {
        set(6, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.comments</code>.
     */
    public String getComments() {
        return (String) get(6);
    }

    /**
     * Setter for <code>kloopzcm.dj_rfc_ci_attributes.created</code>.
     */
    public void setCreated(Timestamp value) {
        set(7, value);
    }

    /**
     * Getter for <code>kloopzcm.dj_rfc_ci_attributes.created</code>.
     */
    public Timestamp getCreated() {
        return (Timestamp) get(7);
    }

    // -------------------------------------------------------------------------
    // Primary key information
    // -------------------------------------------------------------------------

    /**
     * {@inheritDoc}
     */
    @Override
    public Record1<Long> key() {
        return (Record1) super.key();
    }

    // -------------------------------------------------------------------------
    // Record8 type implementation
    // -------------------------------------------------------------------------

    /**
     * {@inheritDoc}
     */
    @Override
    public Row8<Long, Long, Integer, String, String, String, String, Timestamp> fieldsRow() {
        return (Row8) super.fieldsRow();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Row8<Long, Long, Integer, String, String, String, String, Timestamp> valuesRow() {
        return (Row8) super.valuesRow();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<Long> field1() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.RFC_ATTR_ID;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<Long> field2() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.RFC_ID;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<Integer> field3() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.ATTRIBUTE_ID;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<String> field4() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.OLD_ATTRIBUTE_VALUE;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<String> field5() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.NEW_ATTRIBUTE_VALUE;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<String> field6() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.OWNER;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<String> field7() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.COMMENTS;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Field<Timestamp> field8() {
        return DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES.CREATED;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Long component1() {
        return getRfcAttrId();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Long component2() {
        return getRfcId();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Integer component3() {
        return getAttributeId();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String component4() {
        return getOldAttributeValue();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String component5() {
        return getNewAttributeValue();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String component6() {
        return getOwner();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String component7() {
        return getComments();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Timestamp component8() {
        return getCreated();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Long value1() {
        return getRfcAttrId();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Long value2() {
        return getRfcId();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Integer value3() {
        return getAttributeId();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String value4() {
        return getOldAttributeValue();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String value5() {
        return getNewAttributeValue();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String value6() {
        return getOwner();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String value7() {
        return getComments();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Timestamp value8() {
        return getCreated();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value1(Long value) {
        setRfcAttrId(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value2(Long value) {
        setRfcId(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value3(Integer value) {
        setAttributeId(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value4(String value) {
        setOldAttributeValue(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value5(String value) {
        setNewAttributeValue(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value6(String value) {
        setOwner(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value7(String value) {
        setComments(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord value8(Timestamp value) {
        setCreated(value);
        return this;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public DjRfcCiAttributesRecord values(Long value1, Long value2, Integer value3, String value4, String value5, String value6, String value7, Timestamp value8) {
        value1(value1);
        value2(value2);
        value3(value3);
        value4(value4);
        value5(value5);
        value6(value6);
        value7(value7);
        value8(value8);
        return this;
    }

    // -------------------------------------------------------------------------
    // Constructors
    // -------------------------------------------------------------------------

    /**
     * Create a detached DjRfcCiAttributesRecord
     */
    public DjRfcCiAttributesRecord() {
        super(DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES);
    }

    /**
     * Create a detached, initialised DjRfcCiAttributesRecord
     */
    public DjRfcCiAttributesRecord(Long rfcAttrId, Long rfcId, Integer attributeId, String oldAttributeValue, String newAttributeValue, String owner, String comments, Timestamp created) {
        super(DjRfcCiAttributes.DJ_RFC_CI_ATTRIBUTES);

        set(0, rfcAttrId);
        set(1, rfcId);
        set(2, attributeId);
        set(3, oldAttributeValue);
        set(4, newAttributeValue);
        set(5, owner);
        set(6, comments);
        set(7, created);
    }
}
